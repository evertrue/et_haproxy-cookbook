set['newrelic-ng']['license_key'] = Chef::EncryptedDataBagItem.load('secrets', 'api_keys')['newrelic']
