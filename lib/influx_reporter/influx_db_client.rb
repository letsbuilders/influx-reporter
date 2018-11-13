# frozen_string_literal: true

require 'json'
require 'influxdb'

module InfluxReporter
  # @api private
  class InfluxDBClient
    include Logging

    attr_reader :state
    attr_reader :client

    # @param config [InfluxReporter::Configuration]
    def initialize(config)
      @config = config
      @client = InfluxDB::Client.new config.database, config.influx_db.merge(time_precision: 'ns')
      @state = ClientState.new config
    end

    attr_reader :config

    def post(resource, data)
      debug "POST #{resource[:url]}"

      unless state.should_try?
        info 'Temporarily skipping sending to InfluxReporter due to previous failure.'
        return
      end

      begin
        data = [data] unless data.is_a?(Array)
        client.write_points data, nil, nil, resource.fetch(:database, nil)
      rescue StandardError => e
        debug { e.message }
        @state.fail!
        raise
      end

      @state.success!

      true
    end

    class ClientState
      def initialize(config)
        @config = config
        @retry_number = 0
        @last_check = Time.now.utc
      end

      def should_try?
        return true if @status == :online

        interval = ([@retry_number, 6].min**2) * @config.backoff_multiplier
        return true if Time.now.utc - @last_check > interval

        false
      end

      def fail!
        @status = :error
        @retry_number += 1
        @last_check = Time.now.utc
      end

      def success!
        @status = :online
        @retry_number = 0
        @last_check = nil
      end
    end
  end
end
