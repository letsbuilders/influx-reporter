# frozen_string_literal: true

require 'influx_reporter/version'
require 'influx_reporter/configuration'

require 'influx_reporter/logging'
require 'influx_reporter/client'
require 'influx_reporter/error'
require 'influx_reporter/trace_helpers'

require 'influx_reporter/middleware'

require 'influx_reporter/integration/railtie' if defined?(Rails)

require 'influx_reporter/injections'
require 'influx_reporter/injections/net_http'
require 'influx_reporter/injections/redis'
require 'influx_reporter/injections/sinatra'
require 'influx_reporter/injections/sequel'

require 'influx_reporter/integration/delayed_job'
require 'influx_reporter/integration/sidekiq'
require 'influx_reporter/integration/resque'

module InfluxReporter
  # Start the InfluxReporter client
  #
  # @param conf [Configuration] An Configuration object
  def self.start!(conf)
    Client.start! conf
  end

  # Stop the InfluxReporter client
  def self.stop!
    Client.stop!
  end

  def self.started?
    !!Client.inst
  end

  # Start a new transaction or return the currently running
  #
  # @param endpoint [String] A description of the transaction, eg `ExamplesController#index`
  # @param kind [String] The kind of the transaction, eg `app.request.get` or `db.mysql2.query`
  # @param result [Object] Result of the transaction, eq `200` for a HTTP server
  # @yield [InfluxReporter::Transaction] Optional block encapsulating transaction
  # @return [InfluxReporter::Transaction] Unless block given
  def self.transaction(endpoint, kind = nil, result = nil, &block)
    unless client
      return yield if block_given?
      return nil
    end

    client.transaction endpoint, kind, result, &block
  end

  # Starts a new trace under the current Transaction
  #
  # @param signature [String] A description of the trace, eq `SELECT FROM "users"`
  # @param kind [String] The kind of trace, eq `db.mysql2.query`
  # @param extra [Hash] Extra information about the trace
  # @yield [Trace] Optional block encapsulating trace
  # @return [Trace] Unless block given
  def self.trace(signature, kind = nil, extra = nil, &block)
    unless client
      return yield if block_given?
      return nil
    end

    client.trace signature, kind, extra, &block
  end

  def self.flush_transactions
    client&.flush_transactions
  end

  def self.flush_transactions_if_needed
    client&.flush_transactions_if_needed
  end

  # Sets context for future errors
  #
  # @param context [Hash]
  def self.set_context(context)
    client&.set_context context
  end

  # Updates context for errors within the block
  #
  # @param context [Hash]
  # @yield [Trace] Block in which the context is used
  def self.with_context(context, &block)
    unless client
      return yield if block_given?
      return nil
    end

    client.with_context context, &block
  end

  # Send an exception to InfluxReporter
  #
  # @param exception [Exception]
  # @param opts [Hash]
  # @option opts [Hash] :rack_env A rack env object
  # @return [Net::HTTPResponse]
  def self.report(exception, opts = {})
    unless client
      return yield if block_given?
      return nil
    end

    client.report exception, opts
  end

  # Send an exception to InfluxReporter
  #
  # @param message [String]
  # @param opts [Hash]
  # @return [Net::HTTPResponse]
  def self.report_message(message, opts = {})
    client&.report_message message, opts
  end

  # Captures any exceptions raised inside the block
  #
  def self.capture(&block)
    unless client
      return yield if block_given?
      return nil
    end

    client.capture(&block)
  end

  private

  def self.client
    Client.inst
  end
end
