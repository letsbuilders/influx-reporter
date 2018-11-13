# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'influx_reporter/util/timestamp'

module InfluxReporter
  class EventMessage
    extend Logging

    def initialize(config, message, attrs = {})
      @config = config

      @message = message
      @timestamp = Util.nanos

      attrs.each do |k, v|
        send(:"#{k}=", v)
      end

      yield self if block_given?
    end

    attr_reader :config
    attr_accessor :message
    attr_reader :timestamp
    attr_accessor :extra
    attr_accessor :database

    def add_extra(info)
      @extra ||= {}
      @extra.deep_merge! info
    end
  end
end
