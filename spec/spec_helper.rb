# Encoding: utf-8
require 'chefspec'
require 'chefspec/berkshelf'
require 'fog'
require 'rspec/mocks'

require_relative '../libraries/et_haproxy.rb'

RSpec.configure do |config|
  config.before(:each) do
    Fog.mock!
    Fog::Mock.reset
  end
end
