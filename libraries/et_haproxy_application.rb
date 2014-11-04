module EtHaproxy
  # rubocop:disable Metrics/ClassLength
  class Application
    attr_reader :name
    attr_accessor :options

    def initialize(name, conf, global_acls, options = {})
      @name = name
      @conf = conf
      @global_acls = global_acls
      @options = options
    end

    def backend_rule
      { type: 'use_backend', args: "#{backend} if #{acl_string}" }
    end

    def ssl_redirect_rule
      {
        type: 'redirect',
        args: "prefix https://#{endpoint} code 301 if #{acl_string}"
      }
    end

    def generic_redirect_rule
      {
        type: 'redirect',
        args: "#{redirect['type']} #{redirect['destination']}" \
          " code #{redirect['code']} if #{acl_string}"
      }
    end

    def block_rules(options = {})
      block_acl_sets(options).map do |set|
        { type: 'block', args: "if #{set.join(' ')}" }
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def block_acl_sets(options = {})
      o = []
      if endpoint?
        o << (
          [host_endpoint_acl_name] + (
            options[:type] && options[:type] == 'ip' ? allowed_set : []
          )
        )
      end
      if acls?
        acls.map do |acl_set|
          o << (
            acl_set + (
              options[:type] && options[:type] == 'ip' ? allowed_set : []
            )
          )
        end
      end
      o
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def allowed_set
      o = []
      o = allowed['host_groups'].map { |hg| "!src_access_control_#{hg}" } if
        allowed['host_groups']
      o += allowed['acls'].map { |a| "!#{a}" } if allowed['acls']
      o # Satisfies RuboCop
    end

    def legacy_endpoint?
      @conf.keys.include?('endpoint')
    end

    def legacy_endpoint_match
      o = 'hdr_beg(host) -i'
      o += " #{legacy_endpoint.split('.').first}" if legacy_endpoint =~ /\./
      o += " #{legacy_endpoint}"
      o # Satisfies RuboCop
    end

    def short_endpoint
      fail "Could not get endpoint for #{name}" if endpoint.nil?
      endpoint.split('.').first
    end

    def simple_endpoint?
      @conf.key?('endpoint')
    end

    def redirect_permitted?
      return true unless @conf.key?('ssl_disable_redirect')
      !@conf['ssl_disable_redirect']
    end

    def legacy_endpoint
      return @conf['endpoint'] if @conf['endpoint']
    end

    def endpoint
      return legacy_endpoint if legacy_endpoint
      endpoint_acl.fqdn
    end

    def endpoint_acl
      # rubocop:disable Style/EachWithObject
      endpoint_acls = acls.reduce([]) do |collector, acl_set|
        acl_set.each do |acl|
          g_a = global_acl(acl)
          collector << g_a if !g_a.negative? && g_a.host?
        end
        collector
      end
      # rubocop:enable Style/EachWithObject
      fail "Could not find a valid endpoint for app \"#{name}\"" if
        endpoint_acls.empty?
      Chef::Log.debug("Found these valid endpoint acls for #{name}: " \
        "#{endpoint_acls.inspect}")
      endpoint_acls.first
    end

    def global_acl(acl_name)
      @global_acls.find { |acl| acl.name == acl_name } ||
        fail("Acl #{acl_name} not found")
    end

    def host_endpoint_acl_name
      "host_endpoint_#{name}"
    end

    def acl_string
      output = []
      output << acls.map { |a| a.join(' ') } if acls?
      output << host_endpoint_acl_name if simple_endpoint?
      output.join(' or ')
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
  end
  # rubocop:enable Metrics/ClassLength
end
