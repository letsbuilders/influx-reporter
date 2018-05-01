# frozen_string_literal: true

module InfluxReporter
  module Injections
    module Redis
      class Injector
        def install
          ::Redis::Client.class_eval do
            alias_method :call_without_influx_reporter, :call

            def call(command, &block)
              signature = command[0]

              InfluxReporter.trace signature.to_s, 'cache.redis' do
                call_without_influx_reporter(command, &block)
              end
            end
          end
        end
      end
    end

    register 'Redis', 'redis', Redis::Injector.new
  end
end
