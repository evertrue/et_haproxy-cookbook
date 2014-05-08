# Encoding: utf-8
require 'spec_helper'

describe 'et_haproxy::default' do
  let(:chef_run) do
    # This witchcraft allows us to use the include_recipe resource more than
    # once in a single recipe.
    @included_recipes = []
    Chef::RunContext.any_instance.stub(:loaded_recipe?).and_return(false)
    Chef::Recipe.any_instance.stub(:include_recipe) do |i|
      Chef::RunContext.any_instance.stub(:loaded_recipe?).with(i).and_return(true)
      @included_recipes << i
    end
    Chef::RunContext.any_instance.stub(:loaded_recipes).and_return(@included_recipes)

    ChefSpec::Runner.new do |node|
      node.set['haproxy'] = {
        'acls' => {},
        'frontends' => {},
        'applications' => {},
        'backends' => {}
      }
      node.set['platform_family'] = 'debian'
    end.converge('et_haproxy::default')
  end
  before do
    Fog.mock!
    Fog::Mock.reset

    @trusted_networks_obj = {
      'id' => 'trusted_networks',
      'global' => [
        '127.0.0.1/24',
        {
          'name' => 'Fake Name',
          'contact' => 'fake@contact.com',
          'network' => '192.168.19.0/24'
        }
      ]
    }

    # Stub out Pingdom API response
    pingdom_api_res =
      '{"probes":[{"id":28,"country":"Netherlands","city":"Amsterdam",' \
      '"name":"Amsterdam 2, Netherlands","active":true,"hostname":' \
      '"s406.pingdom.com","ip":"95.211.87.85","countryiso":"NL"}]}'
    response = double
    response.stub(:code) { 200 }
    response.stub(:body) { pingdom_api_res }
    response.stub(:headers) { {} }
    RestClient.stub(:get) { response }

    Chef::EncryptedDataBagItem.stub(:load).with('secrets', 'api_keys').and_return(
      'pingdom' => {
        'user' => 'devops@evertrue.com',
        'pass' => 'PASSWORD',
        'app_key' => 'APP_KEY'
      }
    )
    Chef::EncryptedDataBagItem.stub(:load).with('secrets', 'aws_credentials').and_return(
      'Ec2Haproxy' => {
        'access_key_id' => 'SAMPLE_ACCESS_KEY_ID',
        'secret_access_key' => 'SECRET_ACCESS_KEY'
      }
    )
    # Chef::Resource::Template.any_instance.stub(:trusted_networks).with(
    #  @trusted_networks_obj).and_return({
    #     'global' => [
    #       '1.2.3.0/24',
    #       '192.168.0.0/24'
    #     ]
    #   })
    # Chef::Resource::Template.any_instance.stub(:eips).with('Ec2Haproxy').and_return(
    #   [
    #     '1.2.3.4',
    #     '5.6.7.8'
    #   ]
    # )
    # Chef::Resource::Template.any_instance.stub(:instance_ext_ips).with('Ec2Haproxy').and_return(
    #   [
    #     '2.3.4.5',
    #     '3.4.5.6'
    #   ]
    # )
    stub_data_bag('access_control').and_return([
      { id: 'trusted_networks' }
    ])
    stub_data_bag_item('access_control', 'trusted_networks').and_return(@trusted_networks_obj)
  end

  %w(
    haproxy
    socat
    ruby1.9.1
  ).each do |pkg|
    it 'should install package #{pkg}' do
      expect(chef_run).to install_package(pkg).at_converge_time
    end
  end

  it 'should install haproxyctl' do
    expect(chef_run).to install_gem_package('haproxyctl')
  end

  # describe 'trusted_ips' do
  #   it 'should return IPs' do
  #     Chef::Resource::Template.any_instance.should_receive(:trusted_ips).with(
  #       @trusted_networks_obj).and_return(['127.0.0.1/24','192.168.19.0/24'])
  #   end
  # end

  it 'should start/enable service haproxy' do
    expect(chef_run).to enable_service('haproxy')
    expect(chef_run).to start_service('haproxy')
  end

  it 'should render file /etc/default/haproxy' do
    expect(chef_run).to render_file('/etc/default/haproxy').with_content(
      "# This file is managed by chef\n\nENABLED=1")
  end

  it 'should notify haproxy_config_verify to run and haproxy to reload' do
    resource = chef_run.template('/etc/haproxy/haproxy.cfg')
    expect(resource).to notify('execute[haproxy_config_verify]').to(:run)
    expect(resource).to notify('service[haproxy]').to(:reload)
  end

  it 'should include the et_haproxy::syslog recipe' do
    chef_run.should include_recipe 'et_haproxy::syslog'
  end

  it 'should include the et_fog recipe' do
    chef_run.should include_recipe 'et_fog'
  end
end

describe EtHaproxy::Helpers do
  let(:helpers) { Object.new.extend(EtHaproxy::Helpers) }
  before do
    Fog.mock!
    Fog::Mock.reset

    @fog_conn = Fog::Compute.new(
      provider: 'AWS',
      aws_access_key_id: 'MOCK_ACCESS_KEY',
      aws_secret_access_key: 'MOCK_SECRET_KEY'
    )
    @fog_conn.data[:limits][:addresses] = 25
    2.times do
      @fog_conn.allocate_address('vpc')
    end

    helpers.stub(:pingdom_ips).and_return(
      ['95.211.87.85', '204.152.200.42', '85.25.176.167']
    )

    @trusted_networks_obj = {
      'id' => 'trusted_networks',
      'global' => [
        '127.0.0.1/30',
        {
          'name' => 'Fake Name',
          'contact' => 'fake@contact.com',
          'network' => '192.168.19.0/30'
        }
      ]
    }

    Chef::EncryptedDataBagItem.stub(:load).with('secrets', 'aws_credentials').and_return(
      'Ec2Haproxy' => {
        'access_key_id' => 'MOCK_ACCESS_KEY',
        'secret_access_key' => 'MOCK_SECRET_KEY'
      }
    )

    Chef::EncryptedDataBagItem.stub(:load).with('secrets', 'api_keys').and_return(
      'pingdom' => {
        'user' => 'devops@evertrue.com',
        'pass' => 'PASSWORD',
        'app_key' => 'APP_KEY'
      }
    )
  end

  describe 'trusted_ips' do
    it 'should return a hash of IPs in an array under a set name' do
      Fog::Compute::AWS::Mock.any_instance.should_receive(:addresses).and_return(@fog_conn.addresses)

      helpers.trusted_ips(@trusted_networks_obj).should == {
        'global' => [
          '127.0.0.0',
          '127.0.0.1',
          '127.0.0.2',
          '127.0.0.3',
          '192.168.19.0',
          '192.168.19.1',
          '192.168.19.2',
          '192.168.19.3',
          # Pingdom IPs
          '95.211.87.85',
          '204.152.200.42',
          '85.25.176.167'
        ]
      }
    end
  end

  describe 'trusted_networks' do
    it 'should return a hash of networks in an array under a set name' do
      helpers.trusted_networks(@trusted_networks_obj).should == {
        'global' => [
          '127.0.0.1/30',
          '192.168.19.0/30'
        ]
      }
    end
  end

  describe 'eips' do
    it 'should return mock elastic IPs from AWS/Fog' do
      mock_eips = @fog_conn.addresses.map { |a| a.public_ip }

      helpers.eips('Ec2Haproxy').should == mock_eips
    end
  end
end
