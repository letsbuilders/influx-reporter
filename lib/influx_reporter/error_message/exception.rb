# frozen_string_literal: true

module InfluxReporter
  class ErrorMessage
    class Exception < Struct.new(:type, :value, :module)
      SPLIT = '::'

      def self.from(exception)
        new exception.class.to_s, exception.message,
            exception.class.to_s.split(SPLIT)[0...-1].join(SPLIT)
      end
    end
  end
end
