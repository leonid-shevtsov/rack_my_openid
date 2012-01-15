require 'rack/auth/digest/request'

module RackMyOpenid
  module BackportedRackDigestFix
    def self.included(klass)
      klass.class_eval do
        def request
          @request ||= Rack::Request.new(@env)
        end

        def correct_uri?
          request.fullpath == uri
        end
      end
    end
  end
end

Rack::Auth::Digest::Request.send(:include, RackMyOpenid::BackportedRackDigestFix)
