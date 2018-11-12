# frozen_string_literal: true

require 'spec_helper'

module InfluxReporter
  module DataBuilders
    RSpec.describe Event do
      let(:config) { Configuration.new }

      subject do
        Event.new config
      end

      describe '#build' do
        it 'builds an event message dict from an event' do
          event_message = InfluxReporter::EventMessage.new(config, 'Event', extra: { tags: { key: 'tag' }, values: { key: 'value' } })
          example = {
              series: 'events',
              values: {
                  message: 'Event',
                  key: 'value'
              },
              tags: {
                  key: 'tag'
              },
              timestamp: an_instance_of(Integer)
          }
          expect(subject.build(event_message)).to match(example)
        end

        it 'builds an event message dict from an event with a custom series name' do
          event_message = InfluxReporter::EventMessage.new(config, 'Event', extra: { series: 'test' })
          example = {
              series: 'test',
              values: {
                  message: 'Event'
              },
              tags: {},
              timestamp: an_instance_of(Integer)
          }
          expect(subject.build(event_message)).to match(example)
        end
      end
    end
  end
end
