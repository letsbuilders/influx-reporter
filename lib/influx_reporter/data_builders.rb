# frozen_string_literal: true

module InfluxReporter
  # @api private
  module DataBuilders
    class DataBuilder
      def initialize(config)
        @config = config
      end

      attr_reader :config
    end

    %w[transactions error event].each do |f|
      require "influx_reporter/data_builders/#{f}"
    end
  end
end
