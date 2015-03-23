# Encoding: utf-8
default['haproxy']['install_method'] = 'source'
default['haproxy']['conf_dir'] = '/etc/haproxy'

default['haproxy']['access_control']['sets'] = []
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
set['authorization']['sudo']['include_sudoers_d'] = true

default['haproxy']['access_control']['use_eips'] = true
default['haproxy']['access_control']['use_instance_ips'] = true

default['haproxy']['source']['version'] = '1.5.11'
default['haproxy']['source']['url'] =
  'http://www.haproxy.org/download/1.5/src/haproxy-1.5.11.tar.gz'
default['haproxy']['source']['checksum'] =
  '8b5aa462988405f09c8a6169294b202d7f524a5450a02dd92e7c216680f793bf'
default['haproxy']['source']['prefix'] = '/usr'
default['haproxy']['source']['use_pcre'] = false
default['haproxy']['source']['use_openssl'] = false
default['haproxy']['source']['use_zlib'] = false
