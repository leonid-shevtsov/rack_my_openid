require 'cgi'
require 'sinatra/base'
require 'rack_my_openid/handler'
require 'rack_my_openid/provider/configuration'
require 'rack_my_openid/provider/authorisation'
require 'openid/store/memory'
require 'openid/store/filesystem'

module RackMyOpenid
  # Pass the following options to the application:
  # * :credentials (required) - `md5 -s 'username:realm:password'`
  # * :openid (required) - the OpenID you want to authorize
  # * :realm (optional, the default is "rack_my_openid") - an arbitrary resource name for http authentication
  # * :endpoint_url (required) - the URL of the '/openid' path in this application; default is the openid setting + '/openid'
  # * :store_path - path to catalog where OpenID should store its data
  class Provider < Sinatra::Base

    use Rack::Session::Pool

    include RackMyOpenid::Provider::Configuration
    include RackMyOpenid::Provider::Authorisation

    # The identifier page. Right now it's just a reference to the provider endpoint
    get '/' do
      erb :index, :layout => false
    end

    # The provider endpoint. To allow discovery, it displays an HTML page if
    # requested without any parameters.
    get '/openid' do
      if params.empty?
        erb :endpoint
      else
        handle_openid_request
      end
    end

    # The POST endpoint; some OpenID requests are performed with POST and
    # some with GET
    post '/openid' do
      handle_openid_request
    end

    # The "decision page", where the user decides whether he trusts an
    # OpenID consumer or not.
    get '/openid/decide' do
      require_authorisation!

      if @realm = session['realm']
        erb :decide
      else
        redirect '/openid', 302
      end
    end

    # The result of the decision page, redirects back to the consumer after
    # accepting or cancelling the request
    post '/openid/decide' do
      require_authorisation!

      handle_user_confirmation
    end

    def self.openid_store
      @openid_store ||= settings.store_path ? OpenID::Store::Filesystem.new(settings.store_path) : OpenID::Store::Memory.new
    end

    def openid_store
      self.class.openid_store
    end

    def openid_handler
      RackMyOpenid::Handler.new({
          :credentials => settings.credentials,
          :realm => settings.realm,
          :openid => settings.openid,
          :endpoint_url => settings.endpoint_url || settings.openid+'/openid'
        }, openid_store
      )
    end

    def handle_openid_request
      begin
        render_openid_response openid_handler.handle(params, session)
      rescue RackMyOpenid::Handler::NotAuthorised
        throw :halt, @authorisation_response
      rescue RackMyOpenid::Handler::BadRequest
        status 400
        body 'Bad Request'
      rescue RackMyOpenid::Handler::UntrustedRealm => e
        params_hash = {}; params.each{|k,v| params_hash[k] = v}
        session['realm'] = e.realm
        session['openid_params'] = params_hash
        redirect '/openid/decide', 302 
      end
    end

    def handle_user_confirmation
      @realm = session.delete('realm')
      @openid_params_from_session = session.delete('openid_params')
      begin
        if params[:yes]
          session['trusted_realms'] ||= []
          session['trusted_realms'] << @realm
          response = openid_handler.handle(@openid_params_from_session, session)
        else
          response = openid_handler.cancel(@openid_params_from_session)
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
