# Encoding: utf-8
default['haproxy']['access_control']['sets'] = ['global']
default['haproxy']['aws_api_user'] = 'Ec2Haproxy'
default['haproxy']['syslog']['dest'] = '/dev/log'
default['haproxy']['syslog']['facility'] = 'local0'
default['haproxy']['global']['maxconn'] = '100000'
default['haproxy']['global']['socket_file'] = '/var/run/haproxy.socket'
default['haproxy']['global']['admin_user'] = 'root'
default['haproxy']['global']['admin_level'] = 'admin'
default['haproxy']['defaults']['timeout'] = {
  'connect' => '10000',
  'client' => '300000',
  'server' => '300000'
}
default['haproxy']['defaults']['maxconn'] = '60000'

default['haproxy']['stats'] = {
  'uri' => '/stats',
  'port' => '8069',
  'admin_user' => 'admin'
}
default['haproxy']['monitor_uri'] = '/status'
