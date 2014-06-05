# Encoding: utf-8
require 'spec_helper'

describe 'Platform' do
  describe group('haproxy') do
    it { should exist }
  end

  describe user('haproxy') do
    it { should exist }
    it { should belong_to_group 'haproxy' }
  end
end

describe 'HAProxy Service' do
  describe package('haproxy') do
    it { should be_installed }
  end

  [
    8080,
    80,
    8443,
    8069
  ].each do |test_port|
    describe port(test_port) do
      it { should be_listening.with('tcp') }
    end
  end

  describe file('/etc/haproxy/haproxy.cfg') do
    it { should be_file }
    it { should contain 'frontend main' }
    it { should contain 'frontend main_ssl' }
    it { should contain 'block if host_stage-api uri_search or host_test_host' }
    it do
      should contain 'block if host_stage-api uri_search ' \
        '!src_access_control_set_global !src_access_control_eips ' \
        '!src_access_control_instance_ext_ips'
    end
    it do
      should contain 'acl src_access_control_set_global ' \
        'hdr_ip(X-Forwarded-For) 192.168.19.56 192.168.19.57'
    end
    it do
      should contain 'acl host_stage-api hdr_beg(host) -i ' \
        'stage-api stage-api.evertrue.com'
    end
    it do
      should contain(%Q(backend legacyapi-stage
server stage-api-1 stage-api-1.priv.evertrue.com:8080 check))
    end
  end

  describe file('/var/run/haproxy.socket') do
    it { should be_socket }
  end

  describe service('haproxy') do
    it { should be_running }
    it { should be_enabled }
  end
end

describe 'haproxyctl' do
  describe package 'ruby1.9.1' do
    it { should be_installed }
  end

  describe package 'haproxyctl' do
    it { should be_installed.by('gem') }
  end

  describe file '/etc/sudoers.d/control_haproxy' do
    it { should be_file }
    its(:content) { should include '/usr/local/bin/haproxyctl enable server *' }
    its(:content) { should include '/usr/local/bin/haproxyctl disable server *' }
  end
end
