# An example for an OpenID consumer using Sinatra
require 'rubygems'
require 'sinatra/base'
require 'openid'
require 'openid/store/memory'

class OpenIDConsumer < Sinatra::Base
 
  enable :inline_templates

  def self.openid_store
    @openid_store ||= OpenID::Store::Memory.new
  end
  
  def openid_consumer
    @openid_consumer ||= OpenID::Consumer.new(session, self.class.openid_store)
  end

  def root_url
    'http://'+request.host_with_port
  end

  get '/login/openid' do
    openid = params[:openid_identifier] || ''
    begin
      oidreq = openid_consumer.begin(openid)
    rescue OpenID::DiscoveryFailure => why
      "Sorry, we couldn't find your identifier '#{openid}'"
    else
      # You could request additional information here - see specs:
      # http://openid.net/specs/openid-simple-registration-extension-1_0.html
      # oidreq.add_extension_arg('sreg','required','nickname')
      # oidreq.add_extension_arg('sreg','optional','fullname, email')
      
      # Send request - first parameter: Trusted Site,
      # second parameter: redirect target
      redirect oidreq.redirect_url(root_url, root_url + "/login/openid/complete")
    end
  end

  get '/login/openid/complete' do
    oidresp = openid_consumer.complete(params, request.url)

    case oidresp.status
      when OpenID::Consumer::FAILURE
        "Sorry, we could not authenticate you with the identifier '#{oidresp.identity_url}'."

      when OpenID::Consumer::SETUP_NEEDED
        "Immediate request failed - Setup Needed"

      when OpenID::Consumer::CANCEL
        "OpenID authorisation cancelled"

      when OpenID::Consumer::SUCCESS
        # Access additional informations:
        # puts params['openid.sreg.nickname']
        # puts params['openid.sreg.fullname']   
        
        "OpenID authorisation complete"
    end
  end
end
