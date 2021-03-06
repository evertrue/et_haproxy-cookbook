module EtHaproxy
  class Conf
    def initialize(conf, env)
      @conf = conf
      @env = env
    end

    def frontends
      @conf['frontends'].map do |name, conf|
        EtHaproxy::Frontend.new(name, conf, applications)
      end
    end

    def backends
      @conf['backends'].map do |name, conf|
        EtHaproxy::Backend.new(
          name,
          conf,
          recipe_clusters
        )
      end
    end

    def acls
      @conf['acls'].map { |name, conf| EtHaproxy::Acl.new(name, conf) }
    end

    def endpoint_only_acls
      applications.map do |app|
        next unless app.simple_endpoint?
        "acl #{app.host_endpoint_acl_name} #{app.legacy_endpoint_match}"
      end.compact
    end

    def host_acls
      acls.select do |acl|
        acl.type == 'hdr(host)'
      end
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
end
