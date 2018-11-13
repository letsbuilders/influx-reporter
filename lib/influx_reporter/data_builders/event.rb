# frozen_string_literal: true

module InfluxReporter
  module DataBuilders
    class Event < DataBuilder
      # @param event [InfluxReporter::Event]
      def build(event)
        {
            series: build_series_name(event),
            values: build_values(event),
            tags: build_tags(event),
            timestamp: event.timestamp
        }
      end

      private

      # @param event [InfluxReporter::Event]
      def build_series_name(event)
        return event.extra[:series] if event.extra && event.extra[:series].is_a?(String)
        'events'
      end

      # @param event [InfluxReporter::Event]
      def build_tags(event)
        tags = event.extra[:tags] if event.extra && event.extra[:tags].is_a?(Hash)
        tags = event.config.tags.merge(tags || {})
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
