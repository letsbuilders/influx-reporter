# frozen_string_literal: true

require 'spec_helper'

module InfluxReporter
  RSpec.describe Worker do
    before do
      @queue = Queue.new
    end

    let :worker do
      config = build_config
      Worker.new config, @queue, InfluxDBClient.new(config)
    end

    describe '#run' do
      context 'during a loop' do
        before { allow(worker).to receive(:loop).and_yield }

        subject { Thread.new { worker.run }.join 0.05 }

        it 'does nothing with an empty queue' do
          subject
          expect(WebMock).to_not have_requested(:any, /.*/)
        end

        it 'pops the queue' do
          @queue << Worker::PostRequest.new('/errors/', { series: 'test', values: { id: 1 }, timestamp: 0})
          @queue << Worker::PostRequest.new('/errors/', { series: 'test', values: { id: 1 }, timestamp: 1})

          subject

          expect(WebMock).to have_requested(:post, %r{/write}).with(body: 'test id=1i 0')
          expect(WebMock).to have_requested(:post, %r{/write}).with(body: 'test id=1i 1')
        end
      end

      context 'can be stopped by sending a message' do
        it 'loops until stopped' do
          thread = Thread.new do
            worker.run
          end

          @queue << Worker::StopMessage.new

          thread.join

          expect(thread).to_not be_alive
          expect(@queue).to be_empty
        end
      end
    end
  end
end
