class Chef::Recipe::EtHaproxy

  def self.trusted_ips

    require 'ipaddress'

    ips = {}

    Chef::DataBagItem.load("access_control","trusted_networks").each do |set,nets|
      if set != "id"
        ips[set] = [] if ! ips[set]
        nets.each do |n_obj|
          case
          when n_obj.class == String
            n = n_obj
          when n_obj.class == Hash
            n = n_obj['network']
          else
            raise "Unrecognized trusted network type: #{n_obj.class}/#{n_obj.inspect}"
          end
          ips[set] += IPAddress(n).map { |net|
            net.address
          }
        end
      end
    end

    return ips

  end

  def self.eips(aws_api_user)

    require 'fog'

    aws_keys = Chef::EncryptedDataBagItem.load("secrets","aws_credentials")[aws_api_user]

    conn = Fog::Compute.new(
      :provider => "AWS",
      :aws_access_key_id => aws_keys['access_key_id'],
      :aws_secret_access_key => aws_keys['secret_access_key']
    )

    conn.addresses.map { |a|
      a.public_ip
    }

  end

  def self.instance_ext_ips(aws_api_user)

    require 'fog'

    aws_keys = Chef::EncryptedDataBagItem.load("secrets","aws_credentials")[aws_api_user]

    conn = Fog::Compute.new(
      :provider => "AWS",
      :aws_access_key_id => aws_keys['access_key_id'],
      :aws_secret_access_key => aws_keys['secret_access_key']
    )

    conn.servers.select{ |s|
      s.public_ip_address
    }.map{ |s|
      s.public_ip_address
    }

  end

  def self.nodes_for_recipes(env,backends)

    recipes = backends.select{|be,be_conf|
      be_conf['servers_recipe']
    }.map{|be,be_conf|
      be_conf['servers_recipe']
    }

    recipe_search_string = recipes.map{|r| "recipes:" + r }.join(' OR ')
    clusters = Hash.new
    recipes.each do |rec|
      clusters[rec] = []
    end
    r = Chef::Search::Query.new.search(:node, "chef_environment:#{env} AND (#{recipe_search_string})").first
    r.each{|n|
      cluster_recipe = (recipes&n.recipes).first
      clusters[cluster_recipe] << n
    }

    return clusters

  end

  def self.gen_ssl_redirects (applications,acls)

    ssl_redirects = Array.new

    applications.each do |app,app_conf|
      if app_conf['ssl_required']

        # Janky method of finding the actual hostname/fqdn of the request
        # and using it in the redirect.  Note that it doesn't handle
        # the eventuality of regex-based ACLs very well at all.

        app_endpoint_host_acl = app_conf["acls"].flatten.select {|a|
          a !~ /^!/ &&
            acls[a]["type"] == "hdr_beg(host)"
        }.first

        app_endpoint_host = acls[app_endpoint_host_acl]["match"]

        ssl_redirects << {
          "acls" => app_conf["acls"],
          "fqdn" => app_endpoint_host
        }

        if app_conf["endpoint"]

          ssl_redirects << {
            "acls" => [["host_endpoint_#{app}"]],
            "fqdn" => app_conf["endpoint"]
          }

        end # if app_conf["endpoint"]
      end # if ssl_required
    end # node['haproxy']['applications'].each

    return ssl_redirects.uniq

  end # def

end
