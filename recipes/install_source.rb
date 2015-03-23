include_recipe 'build-essential'

case node['platform_family']
when 'debian'
  pcre_pkg = 'libpcre3-dev'
  ssl_pkg = 'libssl-dev'
  zlib_pkg = 'zlib1g-dev'
when 'rhel'
  pcre_pkg = 'pcre-devel'
  ssl_pkg = 'openssl-devel'
  zlib_pkg = 'zlib-devel'
end

package pcre_pkg do
  only_if { node['haproxy']['source']['use_pcre'] }
end

package ssl_pkg do
  only_if { node['haproxy']['source']['use_openssl'] }
end

package zlib_pkg do
  only_if { node['haproxy']['source']['use_zlib'] }
end

download_file_path = ::File.join(Chef::Config[:file_cache_path],
                                 "haproxy-#{node['haproxy']['source']['version']}.tar.gz")
remote_file download_file_path do
  source node['haproxy']['source']['url']
  checksum node['haproxy']['source']['checksum']
  action :create_if_missing
end

ruby_block 'Validating checksum for the downloaded tarball' do
  block do
    checksum = Digest::SHA2.file(download_file_path).hexdigest
    if checksum != node['haproxy']['source']['checksum']
      fail "Checksum of the downloaded file #{checksum} does not match known " \
           "checksum #{node['haproxy']['source']['checksum']}"
    end
  end
end

make_cmd = 'make TARGET=generic'
make_cmd << ' USE_PCRE=1' if node['haproxy']['source']['use_pcre']
make_cmd << ' USE_OPENSSL=1' if node['haproxy']['source']['use_openssl']
make_cmd << ' USE_ZLIB=1' if node['haproxy']['source']['use_zlib']

bash 'compile_haproxy' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar xzf haproxy-#{node['haproxy']['source']['version']}.tar.gz
    cd haproxy-#{node['haproxy']['source']['version']}
    #{make_cmd} && make install PREFIX=#{node['haproxy']['source']['prefix']}
  EOH
  creates "#{node['haproxy']['source']['prefix']}/sbin/haproxy"
end

user 'haproxy' do
  comment 'haproxy system account'
  system true
  shell '/bin/false'
end

directory node['haproxy']['conf_dir']

template '/etc/init.d/haproxy' do
  source 'haproxy-init.erb'
  owner 'root'
  group 'root'
  mode 00755
  variables(
    hostname: node['hostname'],
    conf_dir: node['haproxy']['conf_dir'],
    prefix: node['haproxy']['source']['prefix']
  )
end

service 'haproxy' do
  supports restart: true, status: true, reload: true
  action [:enable, :start]
end
