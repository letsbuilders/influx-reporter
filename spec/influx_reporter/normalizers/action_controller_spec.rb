# frozen_string_literal: true

require 'spec_helper'

module InfluxReporter
  RSpec.describe Normalizers::ActionController do
    let(:config) { Configuration.new payload_tags: %i(geohash), payload_values: %i(uuid) }
    let(:normalizers) { Normalizers.build config }

    describe Normalizers::ActionController::ProcessAction do
      subject do
        normalizers.normalizer_for('process_action.action_controller')
      end

      it 'registers' do
        expect(subject).to be_a Normalizers::ActionController::ProcessAction
      end

      describe '#normalize' do
        it 'normalizes input and updates transaction' do
          transaction = Transaction.new(nil, nil, nil)
          uuid = SecureRandom.uuid

          result = subject.normalize(transaction, 'process_action.action_controller',
                                     controller: 'SomeController',
                                     action: 'index',
                                     uuid: uuid,
                                     geohash: 'foo')

          expect(transaction.endpoint).to eq 'SomeController#index'
          expect(result).to match ['SomeController#index', 'app.controller.action', nil]
          expect(transaction.root_trace.extra).to eq( tags: { geohash: 'foo' }, values: { uuid: uuid } )
        end
      end
    end
  end
end
