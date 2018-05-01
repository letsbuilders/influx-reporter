# frozen_string_literal: true

module InfluxReporter
  # @api private
  module Util
    def self.nearest_minute
      now = Time.now.utc
      now - now.to_i % 60
    end

    def self.nanos
      now = Time.now.utc
      now.to_i * 1_000_000_000 + now.nsec
    end
  end

  require 'influx_reporter/util/inspector'
end
