# frozen_string_literal: true

begin
  require 'sidekiq'
rescue LoadError
end

if defined? Sidekiq
  module InfluxReporter
    module Integration
      class Sidekiq
        KIND = 'worker.sidekiq'.freeze
        PART_KIND = 'worker.sidekiq.part'
        PERFORM_TRACE = 'perform'.freeze
        PERFORM_KIND = 'app.worker.perform'.freeze


        def call(worker, item, queue)
          InfluxReporter.set_context tags: { sidekiq_queue: queue }

          performance_trace(worker, item, queue) do
            yield
          end

        rescue Exception => exception
          if [Interrupt, SystemExit, SignalException].include? exception.class
            raise exception
          end

          InfluxReporter.report exception

          raise
        end

        def performance_trace(worker, item, queue)
          return yield unless worker.class.performance_trace?

          transaction = InfluxReporter.transaction get_worker_name(worker, item), KIND
          transaction.extra_tags do |extra|
            extra[:sidekiq_queue] = queue
          end
          success = 500
          trace = transaction&.trace PERFORM_TRACE, PERFORM_KIND

          begin
            yield
            success = 200
          ensure
            InfluxReporter::Client.inst.current_transaction = nil
            trace&.done
            transaction&.submit(success)
          end
          InfluxReporter.flush_transactions_if_needed
        end

        def get_worker_name(worker, item)
          item['wrapped'.freeze] || worker.class.to_s
        end
      end
    end
  end

  module Sidekiq::Worker
    def with_performance_trace
      unless InfluxReporter::Client.inst
        return yield
      end
      caller = caller_locations(1,1)[0].label
      parent_transaction = InfluxReporter::Client.inst.current_transaction
      InfluxReporter::Client.inst.current_transaction = nil
      transaction = InfluxReporter::Client.inst.transaction "#{self.class}##{caller}", InfluxReporter::Integration::Sidekiq::PART_KIND
      InfluxReporter::Client.inst.current_transaction = transaction
      begin
        result = yield
      ensure
        transaction.submit if transaction
        InfluxReporter::Client.inst.current_transaction = parent_transaction
      end
      InfluxReporter.flush_transactions_if_needed
      result
    end

    def without_performance_trace
      unless InfluxReporter::Client.inst
        return yield
      end
      parent_transaction = InfluxReporter::Client.inst&.current_transaction
      InfluxReporter::Client.inst.current_transaction = nil
      begin
        result = yield
      ensure
        InfluxReporter::Client.inst.current_transaction = parent_transaction
      end
      result
    end

    module ClassMethods
      def skip_performance_trace!
        @skip_performance_trace = true
      end

      def performance_trace?
        !@skip_performance_trace
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
