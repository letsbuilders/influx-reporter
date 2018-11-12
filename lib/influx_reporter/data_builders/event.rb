# frozen_string_literal: true

require 'influx_reporter/filter'

module InfluxReporter
  module DataBuilders
    class Event < DataBuilder
      # @param event [InfluxReporter::Event]
      def build(event)
        {
            series: 'events',
            values: build_values(event),
            tags: build_tags(event),
            timestamp: event.timestamp
        }
      end

      private

      # @param event [InfluxReporter::Event]
      def build_tags(event)
        tags = event.extra[:tags] if event.extra && event.extra[:tags].is_a?(Hash)
        tags = event.config.tags.merge(tags)
        tags.reject { |_, value| value.nil? || value == '' }
      end

      # @param event [InfluxReporter::Event]
      def build_values(event)
        values = {
            message: event.message
        }
        values = event.extra[:values].merge(values) if event.extra && event.extra[:values].is_a?(Hash)

        values.reject { |_, value| value.nil? }
      end
    end
  end
end
