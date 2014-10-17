module EtHaproxy
  class Acl
    attr_reader :name

    def initialize(name, conf)
      @name = name.sub(/^!/, '')
      @negate = name =~ /^!/ ? true : false
      @conf = conf
    end

    # rubocop:disable Style/TrivialAccessors
    def negative?
      @negate
    end
    # rubocop:enable Style/TrivialAccessors

    def conf_line
      o = "acl #{name} #{type}"
      o += ' -i' unless case_sensitive?
      o += " #{shorthostname}" if host?
      o += " #{match}" unless host? && shorthostname == match
      o
    end

    def host?
      type == 'hdr(host)' || type == 'hdr_beg(host)'
    end

    def fqdn
      unless host?
        fail "tried to get hostname but acl #{@name} is not a host acl"
      end
      match
    end

    def case_sensitive?
      @conf['case_sensitive']
    end

    def shorthostname
      fqdn.split('.').first
    end

    def hostnames
      return fqdn if shorthostname == fqdn
      [shorthostname, fqdn]
    end

    def method_missing(sym, *args, &block)
      return @conf[sym.to_s] if @conf.keys.include?(sym.to_s)
      super
    end

    def respond_to?(sym, include_private = false)
      @conf.keys.include?(sym.to_s)
      super(sym, include_private)
    end
  end
end
