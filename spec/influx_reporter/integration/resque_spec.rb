# frozen_string_literal: true

require 'spec_helper'

# :nocov:
begin
  require 'resque'
rescue LoadError
  puts 'Skipping Resque specs'
end
# :nocov:

if defined? Resque
  RSpec.describe 'Resque integration', start_without_worker: true do
    before do
      # using fakeredis
      Resque.redis = Redis.new

      require 'resque/failure/multiple'
      Resque::Failure::Multiple.classes = [InfluxReporter::Integration::Resque]
      Resque::Failure.backend = Resque::Failure::Multiple
    end

    class MyWorker
      @queue = :default

      def self.perform(txt)
        raise Exception, txt
      end
    end

    it 'captures and reports exceptions' do
      Resque.enqueue MyWorker, 'BOOM'

      worker = Resque::Worker.new(:default)
      job = worker.reserve
      worker.perform job

      expect(InfluxReporter::Client.inst.queue.length).to be 1
    end
  end
end
