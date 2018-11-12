# frozen_string_literal: true

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

    def add_extra(info)
      @extra ||= {}
      @extra.merge! info
    end
  end
end
