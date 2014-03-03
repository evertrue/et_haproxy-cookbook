# coding=utf-8

certificate_manage 'evertrue' do
  cert_path     '/etc/ssl'
  cert_file     'STAR.evertrue.com.pem'
  key_file      'evertrue.key'
  chain_file    'gd-bundle.crt'
  nginx_cert true
end

include_recipe 'stunnel::default'

stunnel_connection 'haproxy_ssl' do
  accept    '443'
  connect   '8443'
  notifies  :restart, 'service[stunnel]'
end
