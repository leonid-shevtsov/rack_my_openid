require 'spec_helper'

feature 'HTTP authorisation' do
  setup_app

  before do
    handler.stub(:handle) { OpenID::Server::WebResponse.new(200, {}, 'ok') }
    visit '/?foo=bar'
  end

  scenario 'Without authorisation it should propose to authorise' do
    page.status_code.should == 401
  end

  scenario 'With improper authorisation it should reject the request' do
    page.driver.browser.digest_authorize('vasya', 'pupkin')
    visit '/?foo=bar'
    page.status_code.should == 401
  end

  scenario 'With proper authorisation we should handle the request' do
    page.driver.browser.digest_authorize('correct_login', 'correct_password')
    visit '/?foo=bar'
    page.status_code.should == 200
  end
end
