# frozen_string_literal: true

require 'influx_reporter/filter'

module InfluxReporter
  module DataBuilders
    class Error < DataBuilder
      # @param error_message [InfluxReporter::ErrorMessage]
      def build(error_message)
        h = {
            data: build_values(error_message),
            tags: build_tags(error_message),
            timestamp: error_message.formatted_timestamp
        }

        h = error_message.extra.merge(h) if error_message.extra

        h
      end

      private

      # @param error_message [InfluxReporter::ErrorMessage]
      def build_tags(error_message)
        {
            level: error_message.level,
            excpetion: error_message.exception&.type,
            module: error_message.exception&.module,
            user_id: error_message.user&.id,
            method: error_message.http&.method
        }.reject { |_, value| value.nil? || value == '' }
      end

      # @param error_message [InfluxReporter::ErrorMessage]
      def build_values(error_message)
        data = {
            message: error_message.message,
            culprit: error_message.culprit
        }
        if error_message.http
          data[:url] = error_message.http.url
          data[:user_agent] = error_message.http.user_agent
          data[:user_agent] = error_message.http.user_agent
          data[:uuid] = error_message.http.uuid
        end
        data.reject { |_, value| value.nil? }
      end
    end
  end
end
