case node['haproxy']['install_type']
when 'package'
  package 'haproxy'
else
  include_recipe 'et_haproxy::install_source'
end
