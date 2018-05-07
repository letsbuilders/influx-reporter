# frozen_string_literal: true

require 'logger'

module InfluxReporter
  class Configuration
    DEFAULTS = {
        influx_db: {},
        database: 'endpoints',
        logger: Logger.new(nil),
        context_lines: 3,
        enabled_environments: %w[production],
        excluded_exceptions: [],
        filter_parameters: [/(authorization|password|passwd|secret)/i],
        timeout: 100,
        open_timeout: 100,
        backoff_multiplier: 2,
        current_user_method: :current_user,
        environment: ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'default',
        transaction_post_interval: 60,
        worker_quit_timeout: 5,

        payload_tags: [],
        payload_values: [],

        disable_performance: false,
        disable_errors: false,

        debug_traces: false,

        view_paths: [],

        # for tests
        disable_worker: false
    }.freeze

    attr_accessor :influx_db
    attr_accessor :database
    attr_accessor :logger
    attr_accessor :context_lines
    attr_accessor :enabled_environments
    attr_accessor :excluded_exceptions
    attr_accessor :filter_parameters
    attr_accessor :timeout
    attr_accessor :open_timeout
    attr_accessor :backoff_multiplier
    attr_accessor :use_ssl
    attr_accessor :current_user_method
    attr_accessor :environment
    attr_accessor :transaction_post_interval
    attr_accessor :worker_quit_timeout

    attr_accessor :payload_tags
    attr_accessor :payload_values

    attr_accessor :disable_performance
    attr_accessor :disable_errors

    attr_accessor :debug_traces

    attr_accessor :disable_worker

    attr_accessor :view_paths

    def initialize(opts = {})
      DEFAULTS.merge(opts).each do |k, v|
        send("#{k}=", v)
      end

      yield self if block_given?
    end

    def validate!
      %w[database influx_db].each do |key|
        raise Error, "InfluxReporter Configuration missing `#{key}'" unless send(key)
      end

      true
    rescue Error => e
      logger.error e.message
      false
    end
  end
end
