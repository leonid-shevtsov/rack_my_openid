require 'openid/server'
require 'openid/store/memory'

module RackMyOpenid
  class Handler
    class BadRequest < RuntimeError; end
    class UntrustedRealm < RuntimeError
      attr_reader :realm
      def initialize(realm); @realm = realm; end
      def message; "OpenID realm #{@realm} not trusted by user."; end
    end

    def initialize(options)
      @options = options
    end

    def handle(params, session)
      if request = openid_server.decode_request(params)
        return openid_server.encode_response handle_openid_request(request, session)
      else
        raise BadRequest
      end
    end

    def cancel(params)
      if request = openid_server.decode_request(params)
        return openid_server.encode_response cancel_check_id_request(request) 
      else
        raise BadRequest
      end
    end

  private
    
    def openid_server
      @openid_server ||= OpenID::Server::Server.new(@options[:endpoint_url], openid_store)
    end

    def openid_store
      @openid_store ||= OpenID::Store::Memory 
    end
    
    # Handle a valid OpenID request
    #
    # Requests are handled by the standard openid server,
    # except the main one - which validates your OpenID.
    # So we only have to handle a check_id request
    def handle_openid_request(request, session)
      case request
      when OpenID::Server::CheckIDRequest
        return handle_check_id_request(request, session)
      else
        return openid_server.handle_request(request)
      end
    end

    def handle_check_id_request(request, session)
      if request_provided_invalid_openid?(request)
        return request.answer(false)
      elsif trusted_realm?(request.realm, session)
        return request.answer(true, nil, @options[:openid])
      else
        raise UntrustedRealm.new(request.realm)
      end
    end
    
    def cancel_check_id_request(request)
      request.answer(false)
    end

    # Returns true if the request's claimed id is different from ours
    # 
    # OK, this is an 'inverted truth' method, but it
    # seems appropriate since the opposite assertion isn't
    # 'inverted' (request can either not pass an id or
    # pass a valid id)
    def request_provided_invalid_openid?(request)
      !request.id_select && (request.claimed_id != @options[:openid])
    end

    def trusted_realm?(realm, session)
      trusted_realms(session).include? realm
    end
    
    def trusted_realms(session={})
      @options.fetch(:trusted_realms, []) + session.fetch(:trusted_realms, [])
    end
  end
end
