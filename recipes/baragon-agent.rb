creds = Chef::EncryptedDataBagItem.load('secrets', 'aws_credentials')['Ec2Haproxy']

baragon_agent_jar = 'BaragonAgentService-0.1.5-SNAPSHOT.jar'

s3_file "/usr/share/java/#{baragon_agent_jar}" do
  aws_access_key_id     creds['access_key_id']
  aws_secret_access_key creds['secret_access_key']
  bucket                'ops.evertrue.com'
  remote_path           "/pkgs/#{baragon_agent_jar}"
  owner                 'root'
  group                 'root'
  mode                  0644
end

directory '/etc/baragon'

cookbook_file '/etc/baragon/agent.yml' do
  source 'agent.yml'
  owner  'root'
  group  'root'
  mode   0644
  notifies :restart, 'service[baragon-agent]'
end

template '/etc/init/baragon-agent.conf' do
  source 'baragon-agent.init.erb'
  owner  'root'
  group  'root'
  mode   0644
  notifies :restart, 'service[baragon-agent]'
  variables baragon_jar: baragon_agent_jar,
            config_yaml: '/etc/baragon/agent.yml'
end

service 'baragon-agent' do
  provider Chef::Provider::Service::Upstart
  supports status: true,
           restart: true
  action   [:enable, :start]
end
