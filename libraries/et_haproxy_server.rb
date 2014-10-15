module EtHaproxy
  class Server
    def initialize(conf, backend_conf, check_host)
      @conf = conf
      @backend_conf = backend_conf
      @check_host = check_host
    end

    def server_line
      output = "  server #{name} #{hostname}:#{port}"
      output += ' check' if check_host?
      output += " #{options_string}" if @conf['options']
      output += " #{server_options_string}" if @backend_conf['server_options']
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

    # rubocop:disable Style/TrivialAccessors
    def check_host?
      @check_host
    end
    # rubocop:enable Style/TrivialAccessors

    def options_string
      @conf['options'].join(' ')
    end

    def server_options_string
      @backend_conf['server_options'].join(' ')
    end

    def name
      @conf.name || @conf['name']
    end

    def hostname
      @conf['ipaddress'] || @conf['fqdn']
    end

    def port
      @conf['port'] || @backend_conf['port']
    end
  end
end
