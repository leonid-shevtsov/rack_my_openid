feature 'Decision whether to trust a realm or not' do
  setup_app

  context 'when accessing decision page directly' do
    scenario 'should redirect to the endpoint' do
      visit '/decide'
      page.current_path.should == '/'
    end
  end

  context 'when redirected to the decision page' do
    before do
      handler.stub(:handle) { raise RackMyOpenid::Handler::UntrustedRealm.new('http://my.realm') }
      visit '/'
      handler.stub(:handle) { OpenID::Server::WebResponse.new(200, {}, 'ok') }
    end

    scenario 'Trusting the realm - should allow authentication' do
      handler.should_receive(:handle)
      page.click_button('Yes')
    end

    scenario 'Not trusting the realm - should cancel authentication' do
      handler.should_receive(:cancel)
      page.click_button('No')
    end
  end
end
