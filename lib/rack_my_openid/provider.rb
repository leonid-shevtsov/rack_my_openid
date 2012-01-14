require 'cgi'
require 'sinatra/base'
require 'rack_my_openid/handler'

module RackMyOpenid
  class Provider < Sinatra::Base
    set :root, File.dirname(__FILE__)

    use Rack::Session::Pool

    # authorization
    def authorize!
      response = @auth.call(request.env)
      unless response===true
        throw(:halt, response)
      end
    end

    # Options can contain
    #
    # * :credentials (required) - `md5 -s 'username:realm:password'`
    # * :openid (required) - the OpenID you want to authorize
    # * :realm (optional, the default is "rack_my_openid") - an arbitrary resource name for HTTP Authentication
    def initialize(options = {})
      super()
      @options = default_options.merge options
      @auth = Rack::Auth::Digest::MD5.new(lambda{|e| true}, @options[:realm]) do
        @options[:credentials]
      end
      @auth.opaque = $$.to_s
      @auth.passwords_hashed = true
    end

    get '/openid' do
      if params.empty?
        erb :endpoint
      else
        authorize!
        begin
          render_openid_response RackMyOpenid::Handler.new(@options).handle(params, session)
        rescue RackMyOpenid::Handler::BadRequest
          status 400
          body 'Bad Request'
        rescue RackMyOpenid::Handler::UntrustedRealm => e
          session[:openid_request_params] = params
          session[:realm] = e.realm
          redirect to('/openid/decide'), 302 
        end
      end
    end

    get '/openid/decide' do
      authorize!
      if @realm = session[:realm]
        erb :decide
      else
        redirect to('/openid'), 302
      end
    end

    post '/openid/decide' do
      authorize!
      @realm = session.delete(:realm)
      begin
        if params[:yes]
          session[:trusted_realms] ||= []
          session[:trusted_realms] << @realm
          response = RackMyOpenid::Handler.new(@options).handle(session[:openid_request_params], session)
        else
          response RackMyOpenid::Handler.new(@options).cancel(session[:openid_request_params])
        end
        render_openid_response response
      rescue RackMyOpenid::Handler::BadRequest
        erb :expired
      end
    end

    def render_openid_response(response)
      status response.code
      headers response.headers
      body response.body
    end

    def default_options
      {
        :realm => 'rack_my_openid'
      }
    end
  end
end
