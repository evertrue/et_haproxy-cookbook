# Encoding: utf-8
require 'chefspec'
require 'chefspec/berkshelf'
require 'fog'
require 'rspec/mocks'

require_relative '../libraries/et_haproxy.rb'

RSpec.configure do |config|
end

if defined?(ChefSpec)
  def install_sudo(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:sudo, :install, resource_name)
  end

  def remove_sudo(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:sudo, :remove, resource_name)
  end
end
