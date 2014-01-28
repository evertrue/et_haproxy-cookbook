#
# Cookbook Name:: et_haproxy
# Recipe:: default
#
# Copyright (C) 2013 EverTrue, Inc.
#
# All rights reserved - Do Not Redistribute
#
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

node.set_unless['haproxy']['stats']['admin_password'] = secure_password

case node['platform_family']
  when "debian"
   include_recipe "apt"
end

include_recipe "et_haproxy::syslog"
include_recipe "et_fog"

package "haproxy"

file "/etc/default/haproxy" do
  action :create
  owner "root"
  group "root"
  mode 00644
  content "# This file is managed by chef\n\n" +
    "ENABLED=1"
end

service "haproxy" do
  supports :restart => true, :status => true, :reload => true
  action [ :enable, :start ]
end

# This is necessary because haproxy's service command returns 0
# even if the config file syntax is broken.
execute "haproxy_config_verify" do
  command "/usr/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg"
  action :nothing
end

trusted_networks_obj = Chef::DataBagItem.load("access_control","trusted_networks")

template "/etc/haproxy/haproxy.cfg" do
  source "haproxy.cfg.erb"
  owner "root"
  group "root"
  mode 00644
  variables(
    :trusted_networks => Chef::Recipe::EtHaproxy::trusted_networks( trusted_networks_obj ),
    :trusted_ips => Chef::Recipe::EtHaproxy::trusted_ips( trusted_networks_obj ),
    :eips => Chef::Recipe::EtHaproxy::eips(node['haproxy']['aws_api_user']),
    :instance_ext_ips => Chef::Recipe::EtHaproxy::instance_ext_ips(node['haproxy']['aws_api_user'])
  )
  notifies :run, "execute[haproxy_config_verify]"
  notifies :reload, "service[haproxy]"
end

package "socat"

cookbook_file "/usr/bin/haproxyctl" do
  source "haproxyctl"
  owner "root"
  group "root"
  mode 00755
end
