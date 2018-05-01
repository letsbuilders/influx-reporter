# frozen_string_literal: true

begin
  require 'sidekiq'
rescue LoadError
end

if defined? Sidekiq
  module InfluxReporter
    module Integration
      class Sidekiq
        def call(_worker, _msg, _queue)
          yield
        rescue Exception => exception
          if [Interrupt, SystemExit, SignalException].include? exception.class
            raise exception
          end

          InfluxReporter.report exception

          raise
        end
      end
    end
  end

  Sidekiq.configure_server do |config|
    if Sidekiq::VERSION.to_i < 3
      config.server_middleware do |chain|
        chain.add InfluxReporter::Integration::Sidekiq
      end
    else
      config.error_handlers << lambda do |exception, *|
        InfluxReporter.report exception
      end
    end
  end
end
