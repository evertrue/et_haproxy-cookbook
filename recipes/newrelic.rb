#
# Cookbook Name:: et_haproxy
# Recipe:: newrelic
#
# Copyright (C) 2013 EverTrue, Inc.
#
# All rights reserved - Do Not Redistribute
#

# Install the New Relic repository, system monitor, & Plugin Agent
include_recipe 'newrelic-ng'
include_recipe 'newrelic-ng::plugin-agent-default'

# Pass along YAML settings for Plugin Agent for Apache & APC
node.set['newrelic-ng']['plugin-agent']['service_config'] = <<-EOS
haproxy:
  name: #{node.name}
  host: localhost
  port: #{node['haproxy']['stats']['port']}
  path: #{node['haproxy']['stats']['uri']}
  scheme: http
  username: #{node['haproxy']['stats']['admin_user']}
  password: #{node['haproxy']['stats']['admin_password']}
EOS
