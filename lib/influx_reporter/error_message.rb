# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'influx_reporter/line_cache'
require 'influx_reporter/error_message/exception'
require 'influx_reporter/error_message/stacktrace'
require 'influx_reporter/error_message/http'
require 'influx_reporter/error_message/user'
require 'influx_reporter/util/timestamp'

module InfluxReporter
  class ErrorMessage
    extend Logging

    DEFAULTS = {
        level: :error,
        logger: 'root'
    }.freeze

    def initialize(config, message, attrs = {})
      @config = config

      @message = message
      @timestamp = Util.nanos

      DEFAULTS.merge(attrs).each do |k, v|
        send(:"#{k}=", v)
      end
      @filter = Filter.new config

      yield self if block_given?
    end

    attr_reader :config
    attr_accessor :message
    attr_reader :timestamp
    attr_reader :filter
    attr_accessor :level
    attr_accessor :logger
    attr_accessor :culprit
    attr_accessor :machine
    attr_accessor :extra
    attr_accessor :param_message
    attr_accessor :exception
    attr_accessor :stacktrace
    attr_accessor :http
    attr_accessor :user

    def self.from_exception(config, exception, opts = {})
      message = "#{exception.class}: #{exception.message}"

      if config.excluded_exceptions.include? exception.class.to_s
        info "Skipping excluded exception #{exception.class}"
        return nil
      end

      error_message = new(config, message) do |msg|
        msg.level = :error
        msg.exception = Exception.from(exception)
        msg.stacktrace = Stacktrace.from(config, exception)
      end

      if frames = error_message.stacktrace&.frames
        if first_frame = frames.last
          error_message.culprit = "#{first_frame.filename}:#{first_frame.lineno}:in `#{first_frame.function}'"
        end
      end

      if env = opts[:rack_env]
        error_message.http = HTTP.from_rack_env env, filter: error_message.filter
        error_message.user = User.from_rack_env config, env
      end

      if extra = opts[:extra]
        error_message.extra = extra
      end

      error_message
    end

    def add_extra(info)
      @extra ||= {}
      @extra.deep_merge! info
    end
  end
end
