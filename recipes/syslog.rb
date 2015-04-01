# Encoding: utf-8
service 'rsyslog' do
  supports status: true, restart: true
  action [:nothing]
end

file '/etc/rsyslog.d/haproxy.conf' do
  action :delete
end

log_prefix = ''
rotate_qty = 500

# node['storage'] comes from the "storage" cookbook which is optional.
if node['storage'] &&
   node['storage']['ephemeral_mounts']
  log_prefix = node['storage']['ephemeral_mounts'].first

  rotate_qty = (
    _log_fs_name, log_fs = node['filesystem'].find do |_fs, fs_conf|
      fs_conf['mount'] == log_prefix
    end

    (log_fs['kb_size'].to_i / 1024 / node['haproxy']['log_size_megs'] * 0.70).to_i
  )
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
  size "#{node['haproxy']['log_size_megs']}M"
  frequency 'daily'
  rotate rotate_qty
  sharedscripts true
  options %w(compress notifempty missingok)
  create "644 #{node['rsyslog']['user']} #{node['rsyslog']['group']}"
  postrotate 'reload rsyslog > /dev/null 2>&1 || true'
end
