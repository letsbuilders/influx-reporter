# frozen_string_literal: true

require 'influx_reporter'
require 'rails'

module InfluxReporter
  class Railtie < Rails::Railtie
    config.influx_reporter = ActiveSupport::OrderedOptions.new
    # bootstrap options with the defaults
    Configuration::DEFAULTS.each { |k, v| config.influx_reporter[k] = v }

    initializer 'influx_reporter.configure' do |app|
      config = Configuration.new app.config.influx_reporter do |conf|
        conf.logger = Rails.logger
        conf.view_paths = app.config.paths['app/views'].existent
        conf.tags[:environment] = Rails.env
      end

      if config.enabled_environments.include?(Rails.env)
        if InfluxReporter.start!(config)
          app.config.middleware.insert 0, Middleware
          Rails.logger.info '** [InfluxReporter] Client running'
        else
          # :nocov:
          Rails.logger.info '** [InfluxReporter] Failed to start'
          # :nocov:
        end
      else
        # :nocov:
        Rails.logger.info "** [InfluxReporter] Disabled in #{Rails.env} environment"
        # :nocov:
      end
    end

    config.after_initialize do
      # :nocov:
      require 'influx_reporter/integration/rails/inject_exceptions_catcher'
      if defined?(ActionDispatch::DebugExceptions)
        ActionDispatch::DebugExceptions.send(
            :include, InfluxReporter::Integration::Rails::InjectExceptionsCatcher
        )
      elsif defined?(::ActionDispatch::ShowExceptions)
        ::ActionDispatch::ShowExceptions.send(
            :include, InfluxReporter::Integration::Rails::InjectExceptionsCatcher
        )
      end
      # :nocov:
    end

    rake_tasks do
      # :nocov:
      require 'influx_reporter/tasks'
      # :nocov:
    end
  end
end
