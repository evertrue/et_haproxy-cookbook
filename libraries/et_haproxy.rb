# Encoding: utf-8
module EtHaproxy
  # Make the linter happy
  module Helpers
    def self.validate(config)
      %w(acls frontends applications backends).each do |section|
        fail "haproxy config missing section <#{section}>" unless config[section]
        Chef::Log.info "Section #{section}: #{config[section].inspect}"
      end
    end

    def recipe_servers
      @recipe_servers ||= begin
        recipe_servers = nodes_for_recipes(
            node.chef_environment,
            node['haproxy']['backends']
          )
        Chef::Log.info "recipe_servers inside: #{recipe_servers.inspect}"
        recipe_servers
      end
    end

    def string_acls(acls)
      acls.map { |a| a.join(' ') }.join(' or ')
    end

    def trusted_ips(trusted_network_obj)
      require 'ipaddress'

      ips = {}

      trusted_network_obj.each do |set, nets|
        next unless set != 'id'

        ips[set] = [] unless ips[set]
        nets.each do |n_obj|
          case n_obj
          when String
            n = n_obj
          when Hash || Mash
            n = n_obj['network']
          else
            fail 'Unrecognized trusted network type: ' \
              "#{n_obj.class}/#{n_obj.inspect}"
          end

          ips[set] += IPAddress(n).map(&:address)
        end
      end

      # Add Pingdom IPs to global whitelist
      pingdom_ips.each do |ip|
        ips['global'] += IPAddress(ip).map(&:address)
      end

      ips
    end

    def trusted_networks(trusted_network_obj)
      networks = {}

      trusted_network_obj.reject { |set, _nets| set == 'id' }.each do |set, nets|
        networks[set] = nets.map do |n_obj|
          case n_obj
          when String
            n_obj
          when Hash || Mash
            n_obj['network']
          else
            fail 'Unrecognized trusted network type: ' \
              "#{n_obj.class}/#{n_obj.inspect}"
          end
        end
      end

      networks
    end

    def eips(aws_api_user)
      require 'fog'

      aws_keys = Chef::EncryptedDataBagItem.load('secrets', 'aws_credentials')[aws_api_user]

      conn = Fog::Compute.new(
        provider: 'AWS',
        aws_access_key_id: aws_keys['access_key_id'],
        aws_secret_access_key: aws_keys['secret_access_key']
      )

      conn.addresses.map(&:public_ip)
    end

    def instance_ext_ips(aws_api_user)
      require 'fog'

      aws_keys = Chef::EncryptedDataBagItem.load('secrets', 'aws_credentials')[aws_api_user]

      conn = Fog::Compute.new(
        provider: 'AWS',
        aws_access_key_id: aws_keys['access_key_id'],
        aws_secret_access_key: aws_keys['secret_access_key']
      )

      public_ip_servers = conn.servers.select(&:public_ip_address)
      public_ip_servers.map(&:public_ip_address)
    end

    def backend_options(conf)
      lines = []
      lines << '  cookie ' + conf['cookie_prefix'] + ' prefix' if conf['cookie_prefix']
      lines << '  cookie ' + conf['cookie_insert'] + ' insert indirect' if conf['cookie_insert']
      if conf['check_req'] && conf['check_req']['method']
        line = '  option httpchk ' + conf['check_req']['method']
        line += ' ' + conf['check_req']['url'] if conf['check_req']['url']
        lines << line
      end

      lines
    end

    def backend_servers_clause(conf)
      lines = []

      if conf['servers']
        conf['servers'].each do |server|
          lines << '  ' + server_line(
            server,
            conf
          )
        end
      end

      if conf['servers_recipe']
        fail 'In order to use the servers_recipe clause, you also need ' \
          "to define 'port' for the entire backend." unless conf['port']
        if recipe_servers[conf['servers_recipe']] &&
          recipe_servers[conf['servers_recipe']] != []
          recipe_servers[conf['servers_recipe']].each do |server|
            lines << '  ' + server_line(
              server,
              conf
            )
          end
        else
          Chef::Log.warn "Recipe #{conf['servers_recipe']} does not " \
            'appear to have any associated servers'
        end
      end

      lines
    end

    def backend_clause(name, conf)
      lines = []
      lines << 'backend ' + name
      lines += backend_options(conf) unless conf['mode'] && conf['mode'] == 'tcp'
      lines += backend_servers_clause(conf)
      lines
    end

    def app_endpoint_host_acl(app_conf, acls)
      # Janky method of finding the actual hostname/fqdn of the request
      # and using it in the redirect.  Note that it doesn't handle
      # the eventuality of regex-based ACLs very well at all.
      app_conf['acls'].flatten.find do |a|
        fail(
          'gen_ssl_redirect does not support regular expressions ' \
          'in hdr_reg(host)'
        ) if acls[a] && acls[a]['type'] == 'hdr_reg(host)'
        a !~ /^!/ &&
          acls[a]['type'] =~ /hdr.*\(host\)/
      end
    end

    def gen_ssl_redirects(applications, acls)
      ssl_redirects = []

      applications.each do |app, app_conf|
        next unless app_conf['ssl_required']

        # The logic here is inverted so that we can keep 'false' as the default
        # behavior instead of requiring that all applications specify this
        # option.  It also helps make the template more readable.
        if app_conf['ssl_disable_redirect']
          Chef::Log.debug "App: #{app}, Redirect permitted: no"
          redirect_permitted = false
        else
          Chef::Log.debug "App: #{app}, Redirect permitted: yes"
          redirect_permitted = true
        end

        app_endpoint_host = acls[app_endpoint_host_acl(app_conf, acls)]['match']

        ssl_redirects << {
          'acls' => app_conf['acls'],
          'fqdn' => app_endpoint_host,
          'redirect_permitted' => redirect_permitted
        }

        if app_conf['endpoint']
          ssl_redirects << {
            'acls' => [["host_endpoint_#{app}"]],
            'fqdn' => app_conf['endpoint'],
            'redirect_permitted' => redirect_permitted
          }
        end # if app_conf['endpoint']
      end # node['haproxy']['applications'].each

      ssl_redirect_lines(ssl_redirects.uniq)
    end

    private

    def nodes_for_recipes(env, backends)
      Chef::Log.debug "In nodes_for_recipes with #{env}/#{backends.inspect}"

      recipe_backends = backends.select { |_be, be_conf| be_conf['servers_recipe'] }
      Chef::Log.debug "In nodes_for_recipes: recipe_backends: #{recipe_backends.inspect}"

      recipes = recipe_backends.map { |_be, be_conf| be_conf['servers_recipe'] }
      Chef::Log.debug "In nodes_for_recipes: recipes: #{recipes.join(', ')}"

      recipe_search_string = recipes.map { |r| 'recipes:' + r.gsub(':', '\:') }.join(' OR ')
      Chef::Log.debug "In nodes_for_recipes: search string: #{recipe_search_string}"

      clusters = {}

      recipes.each do |rec|
        clusters[rec] = []
      end

      recipe_nodes = Chef::Search::Query.new.search(
        :node,
        "chef_environment:#{env} AND (#{recipe_search_string})"
      ).first

      Chef::Log.debug "In nodes_for_recipes search result: #{recipe_nodes.inspect}"

      # Make a hash of servers and their associated recipes.
      recipe_nodes.each do |n|
        (recipes & n.recipes).each do |recipe|
          clusters[recipe] << n
        end
      end

      clusters
    end

    def ssl_redirect_lines(redirects)
      redirects.map do |ssl_redirect|
        output = ''
        if ssl_redirect['redirect_permitted'] == true
          output = 'redirect prefix https://' + ssl_redirect['fqdn']
        else
          output = 'block'
        end
        output += ' if ' + string_acls(ssl_redirect['acls'])
        output
      end
    end # def

    def check_option(be_conf)
      if be_conf['check_req'] &&
        be_conf['check_req']['always'] ||
        (be_conf['servers_recipe'] &&
          recipe_servers[be_conf['servers_recipe']].count > 1)
        return ' check'
      else
        return ''
      end
    end

    def server_line(conf, be_conf)
      servername = conf.name || conf['name']
      hostname = conf['ipaddress'] || conf['fqdn']
      port = conf['port'] || be_conf['port']

      output = "server #{servername} #{hostname}:#{port}"
      output += check_option(be_conf)
      output += ' ' + conf['options'].join(' ') if conf['options']
      output += ' ' + be_conf['server_options'].join(' ') if be_conf['server_options']

      output
    end

    # Return an array of IPs from the Pingdom API response
    def pingdom_ips
      require 'rest-client'
      require 'cgi'
      require 'json'

      pingdom_creds = Chef::EncryptedDataBagItem.load('secrets', 'api_keys')['pingdom']

      user    = pingdom_creds['user']
      pass    = pingdom_creds['pass']
      app_key = pingdom_creds['app_key']
      url     = "https://#{CGI.escape user}:#{CGI.escape pass}@api.pingdom.com/api/2.0/probes"
      ips     = []

      res = RestClient.get(url, 'App-Key' => app_key, 'onlyactive' => true)
      res = JSON.parse(res.body, symbolize_names: true)

      res[:probes].each { |item| ips << item[:ip] }

      ips
    end
  end
end
