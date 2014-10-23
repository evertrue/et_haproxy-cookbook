module EtHaproxy
  # rubocop:disable Style/ClassLength
  class Conf
    def initialize(conf, env)
      @conf = conf
      @env = env
    end

    def frontends
      @conf['frontends'].map do |name, conf|
        EtHaproxy::Frontend.new(name,
                                conf,
                                applications)
      end
    end

    def backends
      static = @conf['backends'].map do |name, conf|
        EtHaproxy::Backend.new(name,
                               conf,
                               recipe_clusters)
      end
      automatic = auto_clusters.map do |name, conf|
        Chef::Log.debug("Setting up backend for auto cluster #{name}")
        Chef::Log.debug("Cluster data: #{conf.inspect}")
        EtHaproxy::Backend.new("auto_cluster_#{name}", conf)
      end
      static + automatic
    end

    def acls
      @conf['acls'].map { |name, conf| EtHaproxy::Acl.new(name, conf) }
    end

    def auto_cluster_acls
      Chef::Log.debug("Using this value for auto_clusters: #{auto_clusters.inspect}")
      auto_clusters.map { |_c_name, c_data| c_data['acls'] }.flatten
    end

    def endpoint_only_acls
      applications.map do |app|
        next unless app.simple_endpoint?
        "acl #{app.host_endpoint_acl_name} #{app.legacy_endpoint_match}"
      end.compact
    end

    def host_acls
      acls.select(&:host?)
    end

    def vpn_rules(redirect_port)
      host_acls.reduce([]) do |output, acl|
        output << "acl #{acl.name} #{acl.type} #{acl.hostnames.join(' ')}"
        line = 'redirect prefix ' \
          "http://#{acl.shorthostname}:#{redirect_port} if "
        line += '!' if acl.negative?
        line += acl.name
        output << line
      end
    end

    def method_missing(sym, *args, &block)
      return @conf[sym.to_s.sub(/\?$/, '')] if @conf.keys.include?(
        sym.to_s.sub(/\?$/, '')
      )
      super
    end

    def respond_to?(sym, include_private = false)
      @conf.keys.include?(
        sym.to_s.sub(/\?$/, '')
      )
      super(sym, include_private)
    end

    private

    def applications
      @applications ||= begin
        @conf['applications'].map do |name, conf|
          EtHaproxy::Application.new(
            name,
            conf,
            acls
          )
        end
      end
    end

    def hostname_acl(hostname)
      acl = host_acls.find { |a| a.fqdn == hostname }
      return acl unless acl.nil?
      acl_name = "host_#{hostname.gsub('.', '-')}"
      EtHaproxy::Acl.new(acl_name,
                         'type' => 'hdr(host)',
                         'match' => hostname)
    end

    def context_acl(context)
      EtHaproxy::Acl.new("uri_#{context.gsub('/', '')}",
                         'type' => 'path_beg',
                         'match' => context)
    end

    def auto_clusters
      @auto_clusters ||= begin
        Chef::Log.info 'Gathering "auto clusters" data'

        nodes = Chef::Search::Query.new.search(
          :node,
          "chef_environment:#{@env} AND cluster:*"
        ).first.select { |n| n.key?('cluster') }

        nodes.each_with_object({}) do |n, c|
          c[n['cluster']['name']] = { 'servers' => [] } unless
            c.key?(n['cluster']['name'])
          c[n['cluster']['name']]['servers'] << n
          c[n['cluster']['name']].merge!(n['cluster'])
            .reject { |k, _v| k == 'name' }
          c[n['cluster']['name']].merge!(
            'backend' => "auto_cluster_#{n['cluster']['name']}",
            'acls' => [[
              hostname_acl(n['cluster']['hostname']),
              context_acl(n['cluster']['context'])
            ]]
          )
        end
      end
    end

    def server_recipes
      @server_recipes ||= begin
        all_recipes = @conf['backends'].map do |_b, b_conf|
          b_conf['servers_recipe']
        end.compact.uniq
        all_recipes + all_recipes.map do |recipe|
          next unless recipe !~ /::/
          "#{recipe}::default"
        end.compact
      end
    end

    def recipe_clusters
      recipe_search_string =
        server_recipes.map { |r| 'recipes:' + r.gsub(':', '\:') }.join(' OR ')

      Chef::Log.info 'Building recipe clusters hash'
      nodes = Chef::Search::Query.new.search(
        :node,
        "chef_environment:#{@env} AND (#{recipe_search_string})"
      ).first

      fail "Search string <chef_environment:#{@env} AND " \
        "(#{recipe_search_string})> turned up no results." if nodes.empty?

      clusters = Hash[server_recipes.map { |r| [r, []] }]

      # Make a hash of servers and their associated recipes.
      nodes.each do |n|
        normalize_recipes(server_recipes & n.recipes).each do |recipe|
          clusters[recipe] << n
        end
      end

      Chef::Log.debug('Recipe clusters:')
      Chef::Log.debug(clusters.inspect)

      clusters
    end

    def normalize_recipes(recipes)
      recipes.map { |r| r !~ /\:\:/ ? "#{r}::default" : r }.uniq
    end
  end
  # rubocop:enable Style/ClassLength
end
