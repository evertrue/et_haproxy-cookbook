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

describe 'Syslog Service' do
  describe file('/etc/rsyslog.d/45-haproxy.conf') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode '644' }
    its(:content) { should match(/if \( \\\s+\(\$syslogfacility-text == 'local0'\) and \\/) }
    its(:content) { should match(/\s+\(\$programname == 'haproxy'\) \\\s+\) \\/) }
    its(:content) { should match(%r{then /var/log/haproxy.log\s+# Log no further\.\.\.\s+& ~}) }
  end

  describe service('rsyslog') do
    it { should be_enabled }
    it { should be_running }
  end
end

describe 'HAProxy log rotation' do
  describe file '/etc/logrotate.d/haproxy' do
    it { should be_file }
    its(:content) { should include '/var/log/haproxy.log' }
    its(:content) { should include '100M' }
    its(:content) { should include 'daily' }
    its(:content) { should include 'rotate 10' }
    its(:content) { should include 'sharedscripts' }
    its(:content) { should include 'compress' }
    its(:content) { should include 'notifempty' }
    its(:content) { should include 'missingok' }
    its(:content) { should include 'reload rsyslog > /dev/null 2>&1 || true' }
  end
end

describe 'SSL certificate' do
  describe file('/etc/ssl/certs/STAR.evertrue.com.pem') do
    it { should be_file }
    its(:content) { should include "-----END CERTIFICATE-----\n\n-----BEGIN CERTIFICATE-----" }
  end

  describe file('/etc/ssl/private/evertrue.key') do
    it { should be_file }
    its(:content) { should include '-----BEGIN RSA PRIVATE KEY-----' }
  end
end

describe 'stunnel service' do
  describe port(443) do
    it { should be_listening }
  end

  describe file('/etc/stunnel/stunnel.conf') do
    it { should be_file }
    its(:content) { should include "[haproxy_ssl]\naccept = 443\nconnect = 8443" }
  end

  describe service('stunnel') do
    it { should be_running }
    it { should be_enabled }
  end
end
