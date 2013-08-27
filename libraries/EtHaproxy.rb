class Chef::Recipe::EtHaproxy

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
          "acl" => app_endpoint_host_acl,
          "fqdn" => app_endpoint_host
        }

        if app_conf["endpoint"]

          ssl_redirects << {
            "acl" => "host_endpoint_#{app}",
            "fqdn" => app_conf["endpoint"]
          }

        end # if app_conf["endpoint"]
      end # if ssl_required
    end # node['haproxy']['applications'].each

    return ssl_redirects.uniq

  end # def

end
