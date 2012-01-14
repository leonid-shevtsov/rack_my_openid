require 'cgi'
require 'sinatra/base'
require 'rack_my_openid/handler'

module RackMyOpenid
  class Provider < Sinatra::Base
    use Rack::Session::Pool

    def initialize(options = {})
      super()
      @options = options
    end

    get '/' do
      begin
        render_openid_response RackMyOpenid::Handler.new(@options).handle(params, session)
      rescue RackMyOpenid::Handler::BadRequest
        erb :endpoint
      rescue RackMyOpenid::Handler::UntrustedRealm => e
        session[:openid_request_params] = params
        session[:realm] = e.realm
        redirect to('/decide'), 302 
      end
    end

    get '/decide' do
      if @realm = session[:realm]
        erb :decide
      else
        redirect to('/'), 302
      end
    end

    post '/decide' do
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
  end
end
