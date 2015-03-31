# Encoding: utf-8
service 'rsyslog' do
  supports status: true, restart: true
  action [:nothing]
end

file '/etc/rsyslog.d/haproxy.conf' do
  action :delete
end

log_prefix = ''

# node['storage'] comes from the "storage" cookbook which is optional.
if node['storage'] &&
   node['storage']['ephemeral_mounts']
  log_prefix = node['storage']['ephemeral_mounts'].first
end

node.set['haproxy']['syslog']['file'] = "#{log_prefix}/var/log/haproxy/haproxy.log"

directory File.dirname(node['haproxy']['syslog']['file']) do
  owner     node['rsyslog']['user']
  group     node['rsyslog']['group']
  mode      0755
  action    :create
  recursive true
end

template "#{node['rsyslog']['config_prefix']}/rsyslog.d/45-haproxy.conf" do
  source 'rsyslog.erb'
  owner 'root'
  group 'root'
  mode 00644
  notifies :restart, 'service[rsyslog]'
end

file "#{node['rsyslog']['config_prefix']}/rsyslog.d/99-haproxy.conf" do
  action :delete
end

logrotate_app 'haproxy' do
  cookbook 'logrotate'
  path node['haproxy']['syslog']['file']
  size '100M'
  frequency 'daily'
  rotate 500
  sharedscripts true
  options %w(compress notifempty missingok)
  create "644 #{node['rsyslog']['user']} #{node['rsyslog']['group']}"
  postrotate 'reload rsyslog > /dev/null 2>&1 || true'
end
