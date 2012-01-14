require 'rack_my_openid'
require 'rspec'
require 'capybara/rspec'

module AcceptanceHelper
  def setup_app
    before { Capybara.app = RackMyOpenid::Provider.new({}) }

    let(:handler) { double('RackMyOpenid::Handler') }
    before { RackMyOpenid::Handler.stub(:new).and_return(handler) }
  end
end

RSpec.configure do |config|
  config.extend AcceptanceHelper, :type => :request
end

