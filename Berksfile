source 'https://api.berkshelf.com'

metadata

cookbook 'et_fog',
         git: 'git@github.com:evertrue/et_fog-cookbook.git',
         tag: 'v1.0.5'
         # path: '../et_fog'
cookbook 'et_users',
         github: 'evertrue/et_users-cookbook',
         tag: 'v1.4.2'
         # path: '../et_users'

group :integration do
  cookbook 'et_nginx',
           git: 'git@github.com:evertrue/nginx-cookbook.git',
           tag: 'v2.0.1'
           # path: '../nginx'
  cookbook 'et_hostname',
           git: 'git@github.com:evertrue/et_hostname-cookbook.git',
           tag: 'v1.0.3'
           # path: '../et_hostname'
end
