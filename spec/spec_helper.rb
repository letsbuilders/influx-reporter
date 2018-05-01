# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

DEBUG = ENV.fetch('CI', false)

require 'bundler/setup'
Bundler.require :default
require 'timecop'
require 'webmock/rspec'

SimpleCov.start

require 'influx_reporter'

module InfluxReporter
  class Configuration
    # Override defaults to enable http (caught by WebMock) in test env
    defaults = DEFAULTS.dup.merge enabled_environments: %w[test]
    remove_const(:DEFAULTS)
    const_set(:DEFAULTS, defaults.freeze)
  end
end

RSpec.configure do |config|
  config.backtrace_exclusion_patterns += [%r{/gems/}]

  config.before :each do
    @request_stub = stub_request(:post, /localhost:80/)
  end

  config.around :each, mock_time: true do |example|
    @date = Time.utc(1992, 1, 1)

    def travel(distance)
      Timecop.freeze(@date += distance / 1_000.0)
    end

    travel 0
    example.run
    Timecop.return
  end

  def build_config(attrs = {})
    InfluxReporter::Configuration.new({
        influx_db: { time_precision: 'ns' }
    }.merge(attrs))
  end

  config.around :each, start: true do |example|
    InfluxReporter.start! build_config
    example.call
    InfluxReporter::Client.inst.current_transaction = nil
    InfluxReporter.stop!
  end

  config.around :each, start_without_worker: true do |example|
    InfluxReporter.start! build_config(disable_worker: true)
    example.call
    InfluxReporter::Client.inst.current_transaction = nil
    InfluxReporter.stop!
  end
end

RSpec::Matchers.define :delegate do |method, opts|
  to = opts[:to]
  args = opts[:args]

  match do |delegator|
    unless to.respond_to?(method)
      raise NoMethodError, "no method :#{method} on #{to}"
    end

    if args
      allow(to).to receive(method).with(*args) { true }
    else
      allow(to).to receive(method).with(no_args) { true }
    end

    delegator.send method, *args
  end

  description do
    "delegate :#{method} to #{to}"
  end
end
