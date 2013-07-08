#
# Cookbook Name:: et_haproxy
# Recipe:: default
#
# Copyright (C) 2013 EverTrue, Inc.
# 
# All rights reserved - Do Not Redistribute
#
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

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
  action :enable
end

node.set_unless['haproxy']['stats']['admin_password'] = secure_password

# This is necessary because haproxy's service command returns 0
# even if the config file syntax is broken.
execute "haproxy_config_verify" do
  command "/usr/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg"
  action :nothing
end

template "/etc/haproxy/haproxy.cfg" do
  source "haproxy.cfg.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :run, "execute[haproxy_config_verify]"
  notifies :reload, "service[haproxy]"
end

service "rsyslog" do
  supports :status => true, :restart => true
  action [ :nothing ]
end

template "/etc/rsyslog.d/haproxy" do
  source "rsyslog.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :restart, "service[rsyslog]"
end

cookbook_file "/etc/logrotate.d/haproxy" do
  source "logrotate.conf"
  owner "root"
  group "root"
  mode 00644
end