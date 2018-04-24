require 'spec_helper'

module InfluxReporter
  RSpec.describe Util::Inspector, start_without_worker: true, mock_time: true do

    let(:transaction) do
      InfluxReporter.transaction 'Test' do |transaction|
        travel 10
        InfluxReporter.trace('test 1', 'trace.test') do
          travel 100
          InfluxReporter.trace('test 2', 'trace.test') { travel 150 }
          travel 50
        end
        travel 50
        InfluxReporter.trace('test 3', 'trace.test') do
          travel 100
        end
        travel 1

        transaction
      end
    end
    subject do
      Util::Inspector.new.transaction(transaction, include_parents: true)
    end

    it "doesn't explode" do
      expect { subject }.to_not raise_error
    end

    it "doesn't exceed it's length" do
      expect(subject.split("\n").map(&:length).find { |l| l < 100 })
    end

    # preview
    it "is beautiful" do
      puts subject
    end
  end
end
