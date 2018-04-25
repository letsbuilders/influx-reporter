# frozen_string_literal: true

module InfluxReporter
  # @api private
  class Filter
    MASK = '[FILTERED]'

    def initialize(config)
      @config = config
      @params = rails_filters || config.filter_parameters
    end

    attr_reader :config

    def apply(data, _opts = {})
      case data
        when String
          apply_to_string data, opts = {}
        when Hash
          apply_to_hash data
      end
    end

    def apply_to_string(str, opts = {})
      sep = opts[:separator] || '&'
      kv_sep = opts[:kv_separator] || '='

      str.split(sep).map do |kv|
        key, value = kv.split(kv_sep)
        [key, kv_sep, sanitize(key, value)].join
      end.join(sep)
    end

    def apply_to_hash(hsh)
      hsh.each_with_object({}) do |kv, filtered|
        key, value = kv
        filtered[key] = sanitize(key, value)
      end
    end

    def sanitize(key, value)
      should_filter?(key) ? MASK : value
    end

    private

    def should_filter?(key)
      @params.any? do |param|
        case param
          when String, Symbol
            key.to_s == param.to_s
          when Regexp
            param.match(key)
        end
      end
    end

    def rails_filters
      if defined?(::Rails) && Rails.respond_to?(:application) && Rails.application
        if filters = ::Rails.application.config.filter_parameters
          filters.any? ? filters : nil
        end
      end
    end
  end
end
