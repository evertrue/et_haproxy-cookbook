module EtHaproxy
  class Backend
    attr_reader :name

    def initialize(name, conf, recipe_clusters)
      @name = name
      @conf = conf
      @recipe_clusters = recipe_clusters
    end

    def clause
      output = ["backend #{@name}"]
      output += options unless tcp?
      output += servers
      output
    end

    def method_missing(sym, *args, &block)
      real_name = sym.to_s.sub(/\?$/, '')
      if @conf.keys.include?(real_name)
        # If 'huh' method and key is present, return actual value if boolean
        return @conf[real_name] if sym.to_s =~ /\?$/ &&
          [TrueClass, FalseClass].include?(@conf[real_name].class)
        return @conf[real_name]
      end
      # If 'huh' method but not boolean value, just return t/f if key present
      return @conf.keys.include?(real_name) if sym.to_s =~ /\?$/
      super
    end

    def respond_to?(sym, include_private = false)
      @conf.keys.include?(
        sym.to_s.sub(/\?$/, '')
      )
      super(sym, include_private)
    end

    def tcp?
      @conf.key?('tcp') && @conf['key']
    end

    def servers_recipe
      return @conf['servers_recipe'] if @conf['servers_recipe'] =~ /::/
      "#{@conf['servers_recipe']}::default"
    end

    # def check_req?
    #   @conf.key?('check_req')
    # end

    # def check_req
    #   Chef::Log.info @conf['check_req'].inspect
    #   @conf['check_req']
    # end

    def server_count
      count = 0
      count += @conf['servers'].count if @conf['servers']
      count += recipe_servers.count if servers_recipe?
      count
    end

    private

    def options
      output = []
      output << "  cookie #{cookie_prefix} prefix" if @conf.key?('cookie_prefix')
      output << "  cookie #{cookie_insert} insert indirect" if
        @conf.key?('cookie_insert')
      return output unless check_req? && check_req['method']
      line =  "  option httpchk #{check_req['method']}"
      line += " #{check_req['url']}" if check_req['url']
      output << line
    end

    def check_hosts?
      check_req? && check_req['always'] || server_count > 1
    end

    def servers
      output = []
      if @conf['servers']
        output += @conf['servers'].map do |server|
          EtHaproxy::Server.new(server, @conf, check_hosts?).server_line
        end
        method = '"servers" list'
      end
      if servers_recipe?
        output += recipe_servers.map do |server|
          EtHaproxy::Server.new(server, @conf, check_hosts?).server_line
        end
        method = "servers_recipe: #{servers_recipe}"
      end
      fail "No servers found for backend #{@name}, method: #{method}" if
        output.empty?
      output
    end

    def recipe_servers
      if @recipe_clusters[servers_recipe].empty?
        Chef::Log.error '@recipe_clusters:'
        Chef::Log.error @recipe_clusters.inspect
        fail "servers_recipe #{servers_recipe} has no servers"
      end
      @recipe_clusters[servers_recipe]
    end
  end
end
