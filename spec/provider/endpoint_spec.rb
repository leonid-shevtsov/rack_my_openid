require 'spec_helper'

feature 'Human-readable endpoint' do
  setup_app

  scenario 'Visiting the endpoint' do
    visit '/openid'
    page.should have_content 'This is an OpenID endpoint.'
  end
end
