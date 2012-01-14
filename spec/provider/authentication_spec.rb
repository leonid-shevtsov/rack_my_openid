require 'spec_helper'

feature 'Authentication' do
  setup_app

  scenario 'Bad request' do
    handler.stub(:handle) { raise RackMyOpenid::Handler::BadRequest }
    visit '/'
    page.status_code.should == 200
    page.body.should include 'This is an OpenID endpoint.'
  end

  scenario 'Untrusted realm' do
    handler.stub(:handle) { raise RackMyOpenid::Handler::UntrustedRealm.new('http://my.realm') }
    visit '/'
    page.current_path.should == '/decide'
    page.should have_selector('form')
    page.should have_content('http://my.realm')
  end

  scenario 'Happy case' do
    handler.stub(:handle) { OpenID::Server::WebResponse.new(123, {'X-Test' => 'bar'}, 'testbody') } 
    visit '/'
    page.status_code.should == 123
    page.response_headers['X-Test'].should == 'bar'
    page.source.should == 'testbody'
  end
end
