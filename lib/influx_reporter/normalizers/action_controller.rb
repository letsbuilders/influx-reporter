# frozen_string_literal: true

module InfluxReporter
  module Normalizers
    module ActionController
      class ProcessAction < Normalizer
        register 'process_action.action_controller'
        KIND = 'app.controller.action'

        def normalize(transaction, _name, payload)
          transaction.endpoint = endpoint(payload)
          [transaction.endpoint, KIND, extra(payload)]
        end

        private

        def extra(payload)
          extra = { tags: {}, values: {}}
          config.payload_tags.each { |key| extra[:tags][key] = payload[key] }
          config.payload_values.each { |key| extra[:values][key] = payload[key] }
          extra
        end

        def endpoint(payload)
          "#{payload[:controller]}##{payload[:action]}"
        end
      end
    end
  end
end
