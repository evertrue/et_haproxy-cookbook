source 'https://berks.evertrue.com'
source 'https://supermarket.getchef.com'

metadata

# cookbook 'et_fog', path: '../et_fog'
# cookbook 'et_users', path: '../et_users'

group :integration do
  cookbook 'et_nginx'
           # path: '../nginx'
  cookbook 'et_hostname'
           # path: '../et_hostname'
  cookbook 'et_logger', '~> 3.1'
           # path: '../et_logger'
end

# cookbook 'et_zookeeper', path: '../et_zookeeper'
cookbook 'zookeeper', path: '../../../other/chef-zookeeper'
