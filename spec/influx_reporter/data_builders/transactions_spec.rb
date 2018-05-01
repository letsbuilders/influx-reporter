# frozen_string_literal: true

require 'spec_helper'

module InfluxReporter
  module DataBuilders
    RSpec.describe Transactions, mock_time: true, start_without_worker: true do
      describe '#build' do
        subject do
          transaction1 = Transaction.new(nil, 'endpoint', 'special.kind')
          transaction2 = Transaction.new(nil, 'endpoint', 'special.kind')
          transaction3 = Transaction.new(nil, 'endpoint', 'special.kind')
          travel 100
          transaction1.done 200
          transaction2.done 200
          transaction3.done 500

          transaction4 = InfluxReporter.transaction('endpoint', 'special.kind.foo') do
            travel 100
            InfluxReporter.trace 'things' do
              travel 100
            end
            InfluxReporter.trace 'things', 'db.custom.sql' do
              travel 100
            end
          end.done(500)

          transactions = [transaction1, transaction2, transaction3, transaction4]

          DataBuilders::Transactions.new(Configuration.new).build transactions
        end

        it 'should create proper series names' do
          data = subject
          expect(data.length).to be 6
          expect(data.map { |t| t[:series] }.uniq).to eq %w[special.kind trace.code trace.db]
        end

        it 'combines transactions by result' do
          data = subject
          expect(data.length).to be 6
          expect(data.map { |t| t[:tags][:result] }.compact).to eq [200, 200, 500, 500]
          expect(data.map { |t| t[:values][:duration] }.flatten).to eq [100.0, 100.0, 100.0, 300.0, 100.0, 100.0]
        end
      end
    end
  end
end
