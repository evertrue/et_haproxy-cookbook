# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  config.vm.hostname = "et-haproxy-berkshelf"

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise64"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-vagrant-amd64-disk1.box"

  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  config.vm.network :private_network, ip: "33.33.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.

  # config.vm.network :public_network

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider :virtualbox do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
  #   vb.customize ["modifyvm", :id, "--memory", "1024"]
  # end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  config.ssh.max_tries = 40
  config.ssh.timeout   = 120

  # The path to the Berksfile to use with Vagrant Berkshelf
  # config.berkshelf.berksfile_path = "./Berksfile"

  # Enabling the Berkshelf plugin. To enable this globally, add this configuration
  # option to your ~/.vagrant.d/Vagrantfile file
  config.berkshelf.enabled = true

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to exclusively install and copy to Vagrant's shelf.
  # config.berkshelf.only = []

  # An array of symbols representing groups of cookbook described in the Vagrantfile
  # to skip installing and copying to Vagrant's shelf.
  # config.berkshelf.except = []

  config.vm.provision :shell, :inline => "curl -s -L https://www.opscode.com/chef/install.sh | sudo bash"

  if ENV['CHEF_REPO']
    chef_repo = ENV['CHEF_REPO']
  else
    raise "CHEF_REPO is not defined"
  end

  config.vm.provision :chef_solo do |chef|
    chef.json = {
      "chef_env_long_name" => "VAGRANT",
      "haproxy" => {
        "acls" => {
          "host_testhost1" => {
            "type" => "hdr_beg(host)",
            "match" => "testhost1.example.com"
          },
          "uri_testuri1" => {
            "type" => "path_beg",
            "match" => "/testuri1"
          },
          "uri_testuri2" => {
            "type" => "path_beg",
            "match" => "/testuri2"
          }
        },
        "frontends" => {
          "main" => {
            "port" => "8080",
            "ssl" => false
          },
          "main_ssl" => {
            "port" => "8443",
            "ssl" => true
          }
        },
        "applications" => {
          "testapi-stage" => {
            "acls" => [ "host_testhost1", "!uri_testuri1" ],
            "endpoint" => "stage-testendpoint.example.com",
            "ssl_enabled" => true,
            "ssl_required" => true,
            "backend" => "testapi-stage"
          },
          "testapi2-stage" => {
            "acls" => [ "host_testhost1", "uri_testuri2" ],
            "ssl_enabled" => true,
            "ssl_required" => true,
            "backend" => "test2api-stage"
          }
        },
        "backends" => {
          "testapi-stage" => {
            "balance_algorithm" => "roundrobin",
            "check_req" => {
              "always" => true
            },
            "servers" => [
              {
                "name" => "stage-test-api-1a",
                "fqdn" => "169.254.0.1",
                "port" => "8080"
              }
            ]
          },
          "test2api-stage" => {
            "balance_algorithm" => "roundrobin",
            "check_req" => {
              "always" => true
            },
            "servers" => [
              {
                "name" => "stage-test2-api-1a",
                "fqdn" => "169.254.0.2",
                "port" => "8080"
              }
            ]
          }
        }
      }
    }
    chef.log_level = :debug
    chef.data_bags_path = "#{chef_repo}/data_bags"
    chef.encrypted_data_bag_secret_key_path = "#{ENV['HOME']}/.chef/encrypted_data_bag_secret"

    chef.run_list = [
      "recipe[et_haproxy::default]"
    ]
  end
end
