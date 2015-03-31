# Encoding: utf-8
#
# Cookbook Name:: et_haproxy
# Recipe:: default
#
# Copyright (C) 2013 EverTrue, Inc.
#
# All rights reserved - Do Not Redistribute
#

if Chef::VersionConstraint.new('< 11.10.4').include? Chef::VERSION
  fail 'This recipe requires chef-client version 11.10.4 or higher'
end

::Chef::Recipe.send(:include, OpenSSLCookbook::Password)

# Required for grabbing IPs to whitelist from Pingdom
if platform_family?('debian')
  include_recipe 'apt'
  resources(execute: 'apt-get update').run_action(:run)
end

include_recipe 'build-essential'
chef_gem 'rest-client'

# Include helper code
class ::Chef
  class Resource
    class Template
      include EtHaproxy::Helpers
    end
  end
end

::EtHaproxy::Helpers.validate node['haproxy']

node.set_unless['haproxy']['stats']['admin_password'] = secure_password

package 'haproxy'
package 'curl' # for testing

include_recipe 'et_haproxy::syslog'
include_recipe 'et_fog'

file '/etc/default/haproxy' do
  action :create
  owner 'root'
  group 'root'
  mode 00644
  content "# This file is managed by chef\n\n" \
          'ENABLED=1'
end

# This is necessary because haproxy's service command returns 0
# even if the config file syntax is broken.
execute 'haproxy_config_verify' do
  command "/usr/sbin/haproxy -c -f #{node['haproxy']['conf_dir']}/haproxy.cfg"
  action :nothing
end

trusted_networks_obj = data_bag_item('access_control', 'trusted_networks')

template "#{node['haproxy']['conf_dir']}/haproxy.cfg" do
  source 'haproxy.cfg.erb'
  owner 'root'
  group 'root'
  mode 00644
  variables(
    trusted_networks: trusted_networks(trusted_networks_obj),
    trusted_ips: trusted_ips(trusted_networks_obj),
    eips: eips(node['haproxy']['aws_api_user']),
    instance_ext_ips: instance_ext_ips(node['haproxy']['aws_api_user'])
  )
  notifies :run, 'execute[haproxy_config_verify]'
end

directory "#{node['haproxy']['conf_dir']}/custom-errorfiles" do
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

cookbook_file "#{node['haproxy']['conf_dir']}/custom-errorfiles/403.http" do
  source 'custom-errorfiles/403.http'
  owner 'root'
  group 'root'
  mode 0644
end

service 'haproxy' do
  supports restart: true, status: true, reload: true
  action [:enable, :start]
  subscribes :reload, "template[#{node['haproxy']['conf_dir']}/haproxy.cfg]"
  subscribes :reload, "cookbook_file[#{node['haproxy']['conf_dir']}/custom-errorfiles/403.http]"
end

package 'socat'
package 'ruby1.9.1'
gem_package 'haproxyctl'

sudo 'control_haproxy' do
  user 'deploy'
  nopasswd true
  commands([
    '/usr/local/bin/haproxyctl enable server *',
    '/usr/local/bin/haproxyctl disable server *'
  ])
end

include_recipe 'et_haproxy::stunnel'
include_recipe 'et_security'
