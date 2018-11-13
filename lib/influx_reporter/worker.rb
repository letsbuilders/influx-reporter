# frozen_string_literal: true

module InfluxReporter
  # @api private
  class Worker
    include Logging

    class PostRequest < Struct.new(:resource, :data)
      # require all parameters
      def initialize(resource, data)
        super(resource, data)
      end
    end

    class StopMessage; end

    def initialize(config, queue, influx_client)
      @config = config
      @queue = queue
      @influx_client = influx_client
    end

    attr_reader :config

    def run
      loop do
        while action = @queue.pop
          case action
            when PostRequest
              process_request action
            when StopMessage
              Thread.exit
            else
              raise Error, "Unknown entity in worker queue: #{action.inspect}"
          end
        end
      end
    end

    private

    def process_request(req)
      unless config.validate!
        info 'Invalid config - Skipping posting to influxdb'
        return
      end

      begin
        @influx_client.post(req.resource, req.data)
      rescue => e
        fatal "Failed POST: #{e.inspect}"
        debug e.backtrace.join("\n")
      end
    end
    end
end
