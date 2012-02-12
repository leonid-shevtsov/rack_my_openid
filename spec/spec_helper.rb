require 'support/openid_consumer'
require 'rack_my_openid'
require 'rspec'

module AcceptanceHelper
  def setup_app(stub_handler = true)
    let(:openid) { 'http://localhost:12345' }
    before do
      RackMyOpenid::Provider.set({
        :realm => 'myrealm', 
        :credentials => 'bd1baa373b11c42826d3b15ef77a26d8', 
        :openid => openid
      })
      OpenIDConsumer.use RackMyOpenid::Provider
      @server_thread = Thread.new do
        OpenIDConsumer.run!(:port => 12345)
      end
      sleep(2)
    end

    after do
      @server_thread.terminate
    end

    if stub_handler
      let(:handler) { double('RackMyOpenid::Handler') }
      before { RackMyOpenid::Handler.stub(:new).and_return(handler) }
    end
  end
end

RSpec.configure do |config|
  config.extend AcceptanceHelper, :type => :request
end

