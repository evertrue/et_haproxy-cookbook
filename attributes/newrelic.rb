set['newrelic_meetme_plugin']['license'] =
  Chef::EncryptedDataBagItem.load('secrets', 'api_keys')['newrelic']
