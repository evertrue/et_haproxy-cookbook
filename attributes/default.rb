default['haproxy']['syslog']['host'] = "127.0.0.1"
default['haproxy']['syslog']['facility'] = "local0"
default['haproxy']['global']['maxconn'] = "100000"
default['haproxy']['defaults']['timeout'] = {
  "connect" => "10000",
  "client" => "300000",
  "server" => "300000"
}
default['haproxy']['defaults']['maxconn'] = "60000"

default['haproxy']['stats'] = {
  'uri' => "/stats",
  'port' => '8069',
  'admin_user' => 'admin'
}
default['haproxy']['monitor_uri'] = "/status"