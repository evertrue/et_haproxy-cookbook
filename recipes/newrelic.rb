#
# Cookbook Name:: et_haproxy
# Recipe:: newrelic
#
# Copyright (C) 2013 EverTrue, Inc.
#
# All rights reserved - Do Not Redistribute
#

# Settings for MeetMe Plugin Agent
node.set['newrelic_meetme_plugin']['services'] = {
  'haproxy' => {
    'name'   => node.name,
    'host'   => 'localhost',
    'port'   => node['haproxy']['stats']['port'],
    'path'   => "#{node['haproxy']['stats']['uri']};csv",
    'scheme' => 'http',
    'username' => node['haproxy']['stats']['admin_user'],
    'password' => node['haproxy']['stats']['admin_password']
  }
}

# Install & configure the New Relic MeetMe Plugin Agent
include_recipe 'newrelic_meetme_plugin'
