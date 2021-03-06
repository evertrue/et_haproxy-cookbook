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
    end.converge(described_recipe)
  end

  before do
    stub_haproxy_items
  end

  %w(
    apt
    et_haproxy::syslog
    et_fog
    et_haproxy::stunnel
    et_security
  ).each do |recipe|
    it "should include the #{recipe} recipe" do
      expect(chef_run).to include_recipe recipe
    end
  end

  %w(
    haproxy
    socat
    ruby1.9.1
    curl
  ).each do |pkg|
    it 'should install package #{pkg}' do
      expect(chef_run).to install_package(pkg).at_converge_time
    end
  end

  it 'should render file /etc/default/haproxy' do
    expect(chef_run).to render_file('/etc/default/haproxy').with_content(
      "# This file is managed by chef\n\nENABLED=1")
  end

  it 'should start/enable service haproxy' do
    expect(chef_run).to enable_service('haproxy')
    expect(chef_run).to start_service('haproxy')
  end

  it 'should not execute haproxy_config_verify' do
    exec_haproxy_config_verify = chef_run.execute('haproxy_config_verify')
    expect(exec_haproxy_config_verify).to do_nothing
    expect(chef_run).to_not run_execute('haproxy_config_verify').with(
      command: '/usr/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg')
  end

  it 'should create the haproxy config' do
    expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
      source: 'haproxy.cfg.erb',
      user:  'root',
      group: 'root',
      mode:  00644
    )
  end

  it 'should notify haproxy_config_verify to run and haproxy to reload' do
    resource = chef_run.template('/etc/haproxy/haproxy.cfg')
    expect(resource).to notify('execute[haproxy_config_verify]').to(:run)
    expect(resource).to notify('service[haproxy]').to(:reload)
  end

  it 'should create directory /etc/haproxy/custom-errorfiles' do
    expect(chef_run).to create_directory('/etc/haproxy/custom-errorfiles').with(
      user:  'root',
      group: 'root',
      mode:  0755
    )
  end

  it 'should create cookbook file /etc/haproxy/custom-errorfiles/403.http' do
    expect(chef_run).to create_cookbook_file('/etc/haproxy/custom-errorfiles/403.http').with(
      source: 'custom-errorfiles/403.http',
      owner:  'root',
      group:  'root',
      mode:   0644
    )
  end

  it 'should install haproxyctl' do
    expect(chef_run).to install_gem_package('haproxyctl')
  end

  it 'should add control_haproxy sudoer rules' do
    expect(chef_run).to install_sudo('control_haproxy')
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
      mock_eips = @fog_conn.addresses.map(&:public_ip)

      helpers.eips('Ec2Haproxy').should == mock_eips
    end
  end
end
