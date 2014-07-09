# Encoding: utf-8
require 'spec_helper'

describe 'et_haproxy::syslog' do
  let(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['haproxy'] = {
        'acls' => {},
        'frontends' => {},
        'applications' => {},
        'backends' => {}
      }
      node.set['rsyslog']['config_prefix'] = '/etc'
    end.converge(described_recipe)
  end

  before do
    stub_haproxy_items
  end

  it 'should do nothing with service[rsyslog]' do
    service_rsyslog = chef_run.service('rsyslog')
    expect(service_rsyslog).to do_nothing
  end

  it 'should delete file /etc/rsyslog.d/30-haproxy.conf' do
    expect(chef_run).to delete_file('/etc/rsyslog.d/30-haproxy.conf')
  end

  it 'should create the haproxy rsyslog config' do
    expect(chef_run).to create_template('/etc/rsyslog.d/45-haproxy.conf').with(
      source: 'rsyslog.erb',
      user:  'root',
      group: 'root',
      mode:  00644
    )
  end

  it 'should notify rsyslog to restart' do
    resource = chef_run.template('/etc/rsyslog.d/45-haproxy.conf')
    expect(resource).to notify('service[rsyslog]').to(:restart)
  end

  it 'should delete file /etc/rsyslog.d/99-haproxy.conf' do
    expect(chef_run).to delete_file('/etc/rsyslog.d/99-haproxy.conf')
  end

  it 'should create appropriate log rotate config for haproxy log' do
    expect(chef_run).to create_template('/etc/logrotate.d/haproxy').with(
      cookbook: 'logrotate',
      variables: {
        path:          '"/var/log/haproxy.log"',
        create:        '644 root adm',
        frequency:     'daily',
        size:          '100M',
        rotate:        50,
        sharedscripts: true,
        postrotate:    'reload rsyslog > /dev/null 2>&1 || true',
        prerotate:     '',
        firstaction:   '',
        lastaction:    '',
        options:       %w(compress notifempty missingok),
        # Have to specify all variables, even those we don't set ourselves
        # See github.com/stevendanna/logrotate/pull/38 for ChefSpec matcher
        # that's as-yet-unmerged
        dateformat:    nil,
        maxsize:       nil,
        su:            nil,
        minsize:       nil,
        olddir:        nil,
        compresscmd:   nil,
        uncompresscmd: nil,
        compressext:   nil
      })
  end
end
