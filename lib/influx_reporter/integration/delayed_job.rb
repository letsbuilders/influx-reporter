# frozen_string_literal: true

begin
  require 'active_support'
  require 'delayed_job'
rescue LoadError
end

if defined?(Delayed)
  module Delayed
    module Plugins
      class InfluxReporter < Delayed::Plugin
        callbacks do |lifecycle|
          lifecycle.around(:invoke_job) do |job, *args, &block|
            begin
              block.call(job, *args)
            rescue ::InfluxReporter::Error
              raise # don't report InfluxReporter errors
            rescue Exception => exception
              ::InfluxReporter.report exception
              raise
            end
          end
        end
      end
    end
  end

  Delayed::Worker.plugins << Delayed::Plugins::InfluxReporter
end
