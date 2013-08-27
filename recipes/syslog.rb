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

cookbook_file "/etc/logrotate.d/haproxy" do
  source "logrotate.conf"
  owner "root"
  group "root"
  mode 00644
end
