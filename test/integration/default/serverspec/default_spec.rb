# Encoding: utf-8
require 'spec_helper'

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
  end

  describe group('haproxy') do
    it { should exist }
  end

  describe user('haproxy') do
    it { should exist }
    it { should belong_to_group 'haproxy' }
  end

  describe file('/var/run/haproxy.socket') do
    it { should be_socket }
  end

  describe service('haproxy') do
    it { should be_running }
    it { should be_enabled }
  end
end

describe 'HAProxy Configuration' do
  describe command('curl ') do
    it 'does something' do

    end
  end
end

describe 'haproxyctl' do
  describe package 'ruby1.9.1' do
    it { should be_installed }
  end

  describe package 'haproxyctl' do
    it { should be_installed.by('gem') }
  end
end
