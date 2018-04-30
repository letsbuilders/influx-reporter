# frozen_string_literal: true
require 'influx_reporter/transaction'

module InfluxReporter
  module DataBuilders
    class Transactions < DataBuilder
      def build(transactions)
        data_points = []
        transactions.each do |transaction|
          data_points << build_transaction(transaction)
          transaction.traces.each do |trace|
            next if trace.kind == InfluxReporter::Transaction::ROOT_TRACE_NAME
            data_points << build_trace(trace)
          end
        end
        data_points
      end

      private

      # @param transaction [InfluxReporter::Transaction]
      def build_transaction(transaction)
        {
            series: series(transaction),
            tags: tags(transaction),
            values: values(transaction),
            timestamp: transaction.timestamp
        }
      end

      # @param transaction [InfluxReporter::Transaction, InfluxReporter::Trace]
      # @return [String]
      def series(transaction)
        transaction.kind.split('.').first(2).join('.')
      end

      # @param transaction [InfluxReporter::Transaction]
      # @return [Hash]
      def tags(transaction)
        tags = {
            endpoint: transaction.endpoint,
            result: transaction.result.to_i,
            kind: transaction.kind.split('.')[2..-1].join('.')
        }
        tags = (transaction.root_trace.extra[:tags] || {}).merge(tags)
        clean tags
      end

      # @param transaction [InfluxReporter::Transaction]
      # @return [Hash]
      def values(transaction)
        values = {
            duration: ms(transaction.duration)
        }.merge(values_from_traces(transaction))
        values = (transaction.root_trace.extra[:values] || {}).merge(values)
        clean values
      end

      # @param transaction [InfluxReporter::Transaction]
      # @return [Hash]
      def values_from_traces(transaction)
        values = {}
        transaction.traces.each do |trace|
          next if trace.signature == InfluxReporter::Transaction::ROOT_TRACE_NAME || trace.transaction.root_trace == trace
          values["#{trace.kind}.count"] ||= 0
          values["#{trace.kind}.duration"] ||= 0
          values["#{trace.kind}.count"] += 1
          values["#{trace.kind}.duration"] += ms(trace.duration)
        end
        values
      end

      # @param trace [InfluxReporter::Trace]
      # @return [Hash]
      def build_trace(trace)
        {
            series: "trace.#{trace.kind.split('.').first}",
            tags: trace_tags(trace),
            values: trace_values(trace),
            timestamp: trace.timestamp
        }
      end

      # @param trace [InfluxReporter::Trace]
      def trace_tags(trace)
        tags = {
            endpoint: trace.transaction.endpoint,
            signature: trace.signature,
            kind: trace.kind.split('.')[1..-1].join('.')
        }
        (trace.transaction.root_trace.extra[:tags] || {}).merge(trace.extra[:tags] || {}).merge(tags)
        clean tags
      end

      # @param trace [InfluxReporter::Trace]

      def trace_values(trace)
        values = {
            duration: ms(trace.duration),
            start_time: ms(trace.relative_start)
        }
        values = (trace.extra[:values] || {}).merge(values)
        clean values
      end

      # @param hash [Hash]
      # @return [Hash]
      def clean(hash)
        hash.reject { |_, value| value.nil? || value == '' }
      end

      def ms(nanos)
        nanos.to_f / 1_000_000
      end
    end
  end
end
