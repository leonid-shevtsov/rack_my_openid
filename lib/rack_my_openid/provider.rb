require 'cgi'
require 'sinatra/base'
require 'rack_my_openid/handler'
require 'openid/store/memory'

module RackMyOpenid
  # Pass the following options to the application:
  # * :credentials (required) - `md5 -s 'username:realm:password'`
  # * :openid (required) - the OpenID you want to authorize
  # * :realm (oprtional, the default is "rack_my_openid") - an arbitrary resource name for http authentication
  # * :endpoint_url (required) - the URL of the '/openid' path in this application; default is the openid setting + '/openid'
  class Provider < Sinatra::Base
    set :root, File.dirname(__FILE__)
    
    set :realm, 'rack_my_openid'

    use Rack::Session::Pool

    def self.openid_store
      @openid_store ||= OpenID::Store::Memory.new
    end

    # authorization
    before do
      @authorisation_response = @auth.call(request.env)
      session[:authorised] = @authorisation_response === true
    end

    def require_authorisation!
      unless session[:authorised]
        throw :halt, @authorisation_response
      end
    end

    def initialize
      super
      @auth = Rack::Auth::Digest::MD5.new(lambda{|e| true}, settings.realm) do
        settings.credentials
      end
      @auth.opaque = $$.to_s
      @auth.passwords_hashed = true
    end

    get '/' do
      erb :index, :layout => false
    end

    get '/openid' do
      if params.empty?
        erb :endpoint
      else
        handle_openid_request
      end
    end

    post '/openid' do
      handle_openid_request
    end

    def handle_openid_request
      puts params.inspect
      begin
        render_openid_response RackMyOpenid::Handler.new(handler_options, self.class.openid_store).handle(params, session)
      rescue RackMyOpenid::Handler::NotAuthorised
        throw :halt, @authorisation_response
      rescue RackMyOpenid::Handler::BadRequest
        status 400
        body 'Bad Request'
      rescue RackMyOpenid::Handler::UntrustedRealm => e
        session[:request] = e.request
        session[:realm] = e.request.trust_root
        redirect '/openid/decide', 302 
      end
    end

    get '/openid/decide' do
      require_authorisation!

      if @realm = session[:realm]
        erb :decide
      else
        redirect '/openid', 302
      end
    end

    post '/openid/decide' do
      require_authorisation!

      @realm = session.delete(:realm)
      @openid_request = session.delete(:request)
      begin
        if params[:yes]
          session[:trusted_realms] ||= []
          session[:trusted_realms] << @realm
          response = RackMyOpenid::Handler.new(handler_options, self.class.openid_store).handle(@openid_request, session)
        else
          response RackMyOpenid::Handler.new(handler_options, self.class.openid_store).cancel(@openid_request)
        end
        render_openid_response response
      rescue RackMyOpenid::Handler::BadRequest
        erb :expired
      end
    end

    def render_openid_response(response)
      puts response.body
      status response.code
      headers response.headers
      body response.body
    end

    def handler_options
      {
        :credentials => settings.credentials,
        :realm => settings.realm,
        :openid => settings.openid,
        :endpoint_url => settings.respond_to?(:endpoint_url) ? settings.endpoint_url : settings.openid+'/openid'
      }
    end
  end
end
