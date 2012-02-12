module RackMyOpenid
  class Provider < Sinatra::Base
    module Authorisation
      def self.included(klass)
        klass.instance_eval do
          before do
            @authorisation_response = auth_middleware.call(request.env)
            session['authorised'] = @authorisation_response === true
          end
        end
      end

      def auth_middleware
        unless @auth_middleware
          @auth_middleware = Rack::Auth::Digest::MD5.new(lambda{|e| true}, settings.realm) do
            settings.credentials
          end
          @auth_middleware.opaque = $$.to_s
          @auth_middleware.passwords_hashed = true
        end
        @auth_middleware
      end
      
      def require_authorisation!
        unless session['authorised']
          throw :halt, @authorisation_response
        end
      end
    end
  end
end
