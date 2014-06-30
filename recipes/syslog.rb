# Encoding: utf-8
service 'rsyslog' do
  supports status: true, restart: true
  action [:nothing]
end

file '/etc/rsyslog.d/30-haproxy.conf' do
  action :delete
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
  rotate 50
  sharedscripts true
  options %w(compress notifempty missingok)
  create '644 root adm'
  postrotate 'reload rsyslog > /dev/null 2>&1 || true'
end
