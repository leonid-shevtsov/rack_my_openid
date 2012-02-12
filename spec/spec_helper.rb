require 'rack_my_openid'
require 'rspec'
require 'capybara/rspec'

module AcceptanceHelper
  def setup_app(stub_handler = true)
    before { Capybara.app = RackMyOpenid::Provider.new({:realm => 'myrealm', :credentials => 'bd1baa373b11c42826d3b15ef77a26d8', :openid => 'http://localhost:9000'}) }

    if stub_handler
      let(:handler) { double('RackMyOpenid::Handler') }
      before { RackMyOpenid::Handler.stub(:new).and_return(handler) }
    end
  end

  def assume_authorization
    before {
      visit '/openid?foo=bar'
      page.driver.browser.digest_authorize('correct_login', 'correct_password')
      visit '/openid?foo=bar'
    }
  end
end

RSpec.configure do |config|
  config.extend AcceptanceHelper, :type => :request
end

