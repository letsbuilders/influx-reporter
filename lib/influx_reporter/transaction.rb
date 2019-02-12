# frozen_string_literal: true

require 'influx_reporter/util'

module InfluxReporter
  class Transaction
    ROOT_TRACE_NAME = 'transaction'

    # @param client [InfluxReporter::Client]
    # @param endpoint [String]
    # @param kind [String]
    # @param result [Integer]
    def initialize(client, endpoint, kind = 'code.custom', result = nil)
      @client = client
      @config = client.config if client.respond_to?(:config)
      @endpoint = endpoint
      @kind = kind
      @result = result

      @timestamp = Util.nanos

      @running_traces = []
      @root_trace = Trace.new(self, ROOT_TRACE_NAME, ROOT_TRACE_NAME)
      @traces = [@root_trace]
      @notifications = []

      @start_time = Util.nanos
      @root_trace.start @start_time
    end

    attr_accessor :endpoint, :kind, :result, :duration
    attr_reader :timestamp, :start_time, :traces, :notifications, :root_trace, :config

    def release
      @client.current_transaction = nil
    end

    def done(result = nil)
      @result = result

      @root_trace.done Util.nanos
      @duration = @root_trace.duration

      self
    end

    def done?
      @root_trace.done?
    end

    def submit(result = nil)
      done result

      release

      @client.submit_transaction self

      self
    end

    def trace(signature, kind = nil, extra = nil)
      trace = Trace.new(self, signature, kind, running_traces.clone, extra)

      rel_time = current_offset

      traces << trace

      trace.start rel_time

      return trace unless block_given?

      begin
        result = yield trace
      ensure
        trace.done
      end

      result
    end

    def _trace_started(trace)
      @running_traces.push trace
    end

    def _trace_stopped(trace)
      if @running_traces.last == trace
        @running_traces.pop
      else
        @running_traces.delete trace
      end
    end

    def extra_tags
      @root_trace.extra[:tags] ||= {}
      yield @root_trace.extra[:tags]
    end

    def extra_values
      @root_trace.extra[:values] ||= {}
      yield @root_trace.extra[:values]
    end

    def running_traces
      @running_traces.clone
    end

    def current_trace
      @running_traces.last
    end

    def current_offset
      if curr = current_trace
        return curr.start_time
      end

      start_time
    end

    def inspect
      info = %w[endpoint kind result duration timestamp start_time]
      <<~TEXT
        <Transaction #{info.map { |m| "#{m}:#{send(m).inspect}" }.join(' ')}>
          #{traces.map(&:inspect).join("\n  ")}"
      TEXT
    end
  end
end
