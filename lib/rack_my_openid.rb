require 'rack_my_openid/version'
require 'rack_my_openid/provider'

if Rack.release == '1.2'
  require 'rack_my_openid/backported_rack_digest_fix'
end

module RackMyOpenid

end
