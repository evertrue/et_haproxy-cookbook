service "rsyslog" do
  supports :status => true, :restart => true
  action [ :nothing ]
end

template "/etc/rsyslog.d/30-haproxy.conf" do
  source "rsyslog.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :restart, "service[rsyslog]"
end

logrotate_app "haproxy" do
  cookbook "logrotate"
  path "/var/log/haproxy.log"
  size "100M"
  frequency "daily"
  rotate 10
  sharedscripts true
  options ["compress","notifempty","missingok"]
  create "644 root adm"
  postrotate "reload rsyslog > /dev/null 2>&1 || true"
end
