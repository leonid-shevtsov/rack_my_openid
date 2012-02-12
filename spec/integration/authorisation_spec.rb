require 'spec_helper'
require 'mechanize'


describe 'Authorisation', :type => :request do
  setup_app(false)

  it 'Normal authorisation' do
    a = Mechanize.new
    a.auth 'correct_login', 'correct_password'
    page = a.get 'http://localhost:12345/login/openid?openid_identifier=' + openid
    page = page.forms.first.submit(page.forms.first.button_with(:value => 'Yes'))
    page.body.should == 'OpenID authorisation complete'
  end

end
