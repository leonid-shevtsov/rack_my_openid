require 'spec_helper'

feature 'Authentication' do
  setup_app
  assume_authorization

  scenario 'Bad request' do
    handler.stub(:handle) { raise RackMyOpenid::Handler::BadRequest }
    visit '/openid?foo=bar'
    page.status_code.should == 400
  end

  scenario 'Untrusted realm' do
    handler.stub(:handle) { raise RackMyOpenid::Handler::UntrustedRealm.new('http://my.realm') }
    visit '/openid?foo=bar'
    page.current_path.should == '/openid/decide'
    page.should have_selector('form')
    page.should have_content('http://my.realm')
  end

  scenario 'Happy case' do
    handler.stub(:handle) { OpenID::Server::WebResponse.new(123, {'X-Test' => 'bar'}, 'testbody') } 
    visit '/openid?foo=bar'
    page.status_code.should == 123
    page.response_headers['X-Test'].should == 'bar'
    page.source.should == 'testbody'
  end
end
