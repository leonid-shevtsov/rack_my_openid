module RackMyOpenid
  class Provider < Sinatra::Base
    module Configuration
      def self.included(klass)
        klass.instance_eval do
          set :root, File.absolute_path(File.dirname(__FILE__)+'/..')
          set :credentials, nil
          set :openid, nil
          set :realm, 'rack_my_openid'
          set :endpoint_url, nil
          set :store_path, nil
        end
      end
    end
  end
end
