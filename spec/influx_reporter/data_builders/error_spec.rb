# frozen_string_literal: true

require 'spec_helper'

module InfluxReporter
  module DataBuilders
    RSpec.describe Error do
      let(:config) { Configuration.new }

      subject do
        Error.new config
      end

      def real_exception
        1 / 0
      rescue ZeroDivisionError => e
        e
      end

      describe '#build' do
        it 'builds an error dict from an exception' do
          error_message = ErrorMessage.from_exception config, real_exception
          example = {
              series: 'errors',
              values: {
                  message: 'ZeroDivisionError: divided by 0',
                  culprit: "influx_reporter/data_builders/error_spec.rb:15:in `/'"
              },
              tags: {
                  level: :error,
                  excpetion: 'ZeroDivisionError'
              },
              timestamp: an_instance_of(Integer)
          }
          expect(subject.build(error_message)).to match(example)
        end
      end
    end
  end
end
