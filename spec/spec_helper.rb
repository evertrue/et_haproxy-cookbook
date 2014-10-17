# Encoding: utf-8
require 'chefspec'
require 'chefspec/berkshelf'
require 'fog'
require 'rspec/mocks'
require 'coveralls'

Coveralls.wear!

require_relative '../libraries/et_haproxy_helpers.rb'

RSpec.configure do |config|
  config.platform = 'ubuntu'
  config.version = '12.04'
end

require_relative 'support/matchers'

def stub_haproxy_items
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

  stub_data_bag('access_control').and_return([
    { id: 'trusted_networks' }
  ])
  stub_data_bag_item('access_control', 'trusted_networks').and_return(@trusted_networks_obj)
end
