# frozen_string_literal: true

module InfluxReporter
  module Normalizers
    module ActionController
      class ProcessAction < Normalizer
        register 'process_action.action_controller'
        KIND = 'app.controller.action'

        def normalize(transaction, _name, payload)
          transaction.endpoint = endpoint(payload)
          [transaction.endpoint, KIND, nil]
        end

        private

        def endpoint(payload)
          "#{payload[:controller]}##{payload[:action]}"
        end
      end
    end
  end
end
