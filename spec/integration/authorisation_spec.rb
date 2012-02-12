require 'spec_helper'
require 'support/openid_consumer'

feature 'Authorisation' do
  setup_app(false)
  
  before do
    Capybara.default_driver = :selenium
  end

  let(:consumer_url) { 'http://localhost:9393/login/openid' }
  let(:our_url) { 'http://localhost:9000' }

  scenario 'Normal authorisation' do
    visit consumer_url + '?openid_identifier=' + CGI.escape(our_url)
    puts page.body
  end

end
