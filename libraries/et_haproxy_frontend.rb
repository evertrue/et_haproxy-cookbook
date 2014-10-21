module EtHaproxy
  class Frontend
    attr_reader :name, :conf

    def initialize(name, conf, applications, auto_clusters)
      @name = name
      @conf = conf
      @applications = applications
      @auto_clusters = auto_clusters
    end

    def access_control_apps
      @applications.select { |app| app.respond_to?('access_control') }
    end

    def legacy_endpoint_apps
      @applications.select(&:legacy_endpoint?)
    end

    def vpn?
      @conf.key?('vpn')
    end

    def routing_rule_lines
      # This method really just exists to make sure that rules are rendered
      # in the correct order (otherwise haproxy throws a bunch of warnings).
      # It does not do any rule wrangling.

      rules = routing_rules
      Chef::Log.debug("Writing routing rules: #{rules.inspect}")
      %w(
        block
        redirect
        use_backend
      ).reduce([]) do |collector, type|
        Chef::Log.debug("Writing #{type} rules")
        collector + rules.map do |r|
          (r[:type] == type &&
            "#{r[:type]} #{r[:args]}") || nil
        end.compact
      end.uniq
    end

    def routing_rules
      Chef::Log.debug("Frontend #{name} SSL setting: #{ssl.inspect}")
      # rubocop:disable Style/EachWithObject
      output = @applications.reduce([]) do |rules, app|
        rules << routing_rule(app)
        case
        when prevent_ssl_redirect?(app)
          Chef::Log.debug("#{app.name} prevent_ssl_redirect: true")
          rules += app.block_rules
        when app.access_control? &&
          !app.block_acl_sets(type: 'ip').empty? &&
          !prevent_ssl_redirect?(app)
          Chef::Log.debug("#{app.name} IP-based block rules: true")
          rules += app.block_rules(type: 'ip')
        end
        rules
      end.compact
      # rubocop:enable Style/EachWithObject
      Chef::Log.debug "routing_rules output: #{output.inspect}"
      output
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

    def routing_rule(app)
      validate_rule(app)

      if show_backend_rule?(app)
        app.backend_rule
      elsif needs_ssl_redirect?(app)
        app.ssl_redirect_rule
      elsif app.redirect?
        app.generic_redirect_rule
      end
    end

    def validate_rule(app)
      fail "#{app.name} contains contradictory SSL requirements" if
        app.ssl_required? && !app.ssl_enabled?
      fail "#{app.name} contains both 'backend' and 'redirect' rules" if
        app.backend? && app.redirect?
    end

    def show_backend_rule?(app)
      app.backend? && ((!ssl && !app.ssl_required?) || (ssl && app.ssl_enabled?))
    end

    def routable?(app)
      app.backend? || app.redirect?
    end

    def prevent_ssl_redirect?(app)
      !ssl &&
        app.ssl_enabled? &&
        app.ssl_required? &&
        !app.redirect_permitted?
    end

    def needs_ssl_redirect?(app)
      !ssl &&
        app.ssl_enabled? &&
        app.ssl_required? &&
        app.redirect_permitted?
    end
  end
end
