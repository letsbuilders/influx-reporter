# frozen_string_literal: true

module InfluxReporter
  module Integration
    module Rails
      module InjectExceptionsCatcher
        def self.included(cls)
          cls.send(:alias_method, :render_exception_without_influx_reporter, :render_exception)
          cls.send(:alias_method, :render_exception, :render_exception_with_influx_reporter)
        end

        def render_exception_with_influx_reporter(env, exception, *args)
          begin
            InfluxReporter.report(exception, tags: { rack_env: env }) if InfluxReporter.started?
          rescue
            ::Rails.logger.error "** [InfluxReporter] Error capturing or sending exception #{$ERROR_INFO}"
            ::Rails.logger.debug $ERROR_INFO.backtrace.join("\n")
          end

          render_exception_without_influx_reporter(env, exception, *args)
        end
      end
    end
  end
end
