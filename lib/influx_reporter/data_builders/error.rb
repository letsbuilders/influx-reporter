# frozen_string_literal: true

require 'influx_reporter/filter'

module InfluxReporter
  module DataBuilders
    class Error < DataBuilder
      # @param error_message [InfluxReporter::ErrorMessage]
      def build(error_message)
        {
            series: 'errors',
            values: build_values(error_message),
            tags: build_tags(error_message),
            timestamp: error_message.timestamp
        }
      end

      private

      # @param error_message [InfluxReporter::ErrorMessage]
      def build_tags(error_message)
        tags = {
            level: error_message.level,
            excpetion: error_message.exception&.type,
            module: error_message.exception&.module,
            user_id: error_message.user&.id,
            method: error_message.http&.method
        }
        tags = error_message.extra[:tags].merge(tags) if error_message.extra && error_message.extra[:tags].is_a?(Hash)
        tags = error_message.config.tags.merge(tags)
        tags.reject { |_, value| value.nil? || value == '' }
      end

      # @param error_message [InfluxReporter::ErrorMessage]
      def build_values(error_message)
        values = {
            message: error_message.message,
            culprit: error_message.culprit
        }
        if error_message.http
          values[:url] = error_message.http.url
          values[:user_agent] = error_message.http.user_agent
          values[:user_agent] = error_message.http.user_agent
          values[:uuid] = error_message.http.uuid
        end
        values = error_message.extra[:values].merge(values) if error_message.extra && error_message.extra[:values].is_a?(Hash)

        values.reject { |_, value| value.nil? }
      end
    end
  end
end
