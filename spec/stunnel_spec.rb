# Encoding: utf-8
require 'spec_helper'

describe 'et_haproxy::stunnel' do
  let(:chef_run) { ChefSpec::Runner.new .converge(described_recipe) }

  before do
    stub_haproxy_items
  end

  it 'should manage evertrue certificate' do
    expect(chef_run).to create_certificate_manage('evertrue').with(
      cert_path:  '/etc/ssl',
      cert_file:  'STAR.evertrue.com.pem',
      key_file:   'evertrue.key',
      chain_file: 'gd-bundle.crt',
      nginx_cert: true
    )
  end

  it 'should include the stunnel::default recipe' do
    expect(chef_run).to include_recipe 'stunnel::default'
  end

  it 'should create stunnel_connection haproxy_ssl' do
    expect(chef_run).to create_stunnel_connection('haproxy_ssl').with(
      accept:  '443',
      connect: '8443'
    )
  end

  it 'should notify stunnel to restart on changes to stunnel_connection[haproxy_ssl]' do
    resource = chef_run.stunnel_connection('haproxy_ssl')
    expect(resource).to notify('service[stunnel]').to(:restart)
  end
end
