# frozen_string_literal: true

module InfluxReporter
  module Util
    module Timestamp
      def formatted_timestamp(t = Time.now)
        format('%d%09d', t.to_i, t.nsec).to_i
      end
    end
  end
end
