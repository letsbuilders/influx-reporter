# frozen_string_literal: true

module InfluxReporter
  module Normalizers
    module ActionController
      class ProcessAction < Normalizer
        register 'process_action.action_controller'
        KIND = 'app.controller.action'

        def normalize(transaction, _name, payload)
          transaction.endpoint = endpoint(payload)
          extra(transaction, payload)
          [transaction.endpoint, KIND, nil]
        end

        private

        # @param transaction [InfluxReporter::Transaction]
        def extra(transaction, payload)
          transaction.extra_tags do |tags|
            config.payload_tags.each { |key| tags[key] = payload[key] }
          end
          transaction.extra_values do |values|
            config.payload_values.each { |key| values[key] = payload[key] }
          end
        end

        def endpoint(payload)
          "#{payload[:controller]}##{payload[:action]}"
        end
      end
    end
  end
end
