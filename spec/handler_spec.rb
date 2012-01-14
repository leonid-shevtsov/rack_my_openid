require 'spec_helper'

shared_examples_for 'a valid request' do
  context 'when realm is trusted via options' do
    let(:options_with_realm) { options.merge({:trusted_realms => [request.realm]}) }
    it 'should answer true' do
      described_class.new(options_with_realm).handle(params, session).should == 'answered true'
    end
  end

  context 'when realm is trusted via session' do
    let(:session) { {:trusted_realms => [request.realm] } }
    it 'should answer true' do
      described_class.new(options).handle(params, session).should == 'answered true'
    end
  end
  
  context 'when realm is not trusted' do
    it 'should raise an error' do
      expect {
        described_class.new(options).handle(params, session)
      }.to raise_error(RackMyOpenid::Handler::UntrustedRealm)
    end
  end
end

describe RackMyOpenid::Handler do
  let(:options) { {:openid => 'http://myopenid.myopenid/' } }
  let(:params) { {} }
  let(:session) { {} }
  let(:server) { 
    server = double('OpenID::Server::Server') 
    server.should_receive(:decode_request).with(params) { request }
    server
  }
  before(:each) do
    OpenID::Server::Server.stub(:new) { server }
  end

  context 'with bad params' do
    let(:params) { {:bad => :params} }
    let(:request) { false }
  
    it 'should raise error' do
      expect {
        described_class.new(options).handle(params, session)
      }.to raise_error(RackMyOpenid::Handler::BadRequest)
    end
  end

  context 'with a non-check_id request' do
    let(:params) { {:mode => 'some_mode' } }
    let(:request) { Object.new } 
    let(:response) { double('Response') }

    it 'should pass the request to the server' do
      server.should_receive(:handle_request).with(request) { response }
      server.should_receive(:encode_response).with(response)
      described_class.new(options).handle(params, session)
    end
  end

  context 'with a check_id request' do
    let(:params) { {:mode => 'check_id'} }
    let(:request) {
      request = OpenID::Server::CheckIDRequest.new(nil, nil, nil)
      request.stub(:realm) { 'http://my.realm' }
      request.stub(:answer).with(true, nil, options[:openid]) { 'answered true' }
      request.stub(:answer).with(false) { 'answered false' }
      request
    }
    before do
      server.stub(:encode_response) {|params| params }
    end

    context 'and a valid openid' do
      before do
        request.stub(:id_select) { false }
        request.stub(:claimed_id) { options[:openid] }
      end

      it_should_behave_like 'a valid request'
    end

    context 'and an invalid openid' do
      before do
        request.stub(:id_select) { false }
        request.stub(:claimed_id) { 'bad id' }
      end

      it 'should answer false' do
        described_class.new(options).handle(params, session).should == 'answered false'
      end
    end

    context 'and no openid' do
      before do
        request.stub(:id_select) { true }
        request.stub(:claimed_id) { nil }
      end

      it_should_behave_like 'a valid request'
    end
  end
end

