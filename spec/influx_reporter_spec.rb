require 'spec_helper'

RSpec.describe InfluxReporter do

  it { should_not be_started }

  describe "self.start!" do
    it "delegates to client" do
      conf = InfluxReporter::Configuration.new app_id: 'x', organization_id: 'y', secret_token: 'z'
      expect(InfluxReporter::Client).to receive(:start!).with(conf) { true }
      InfluxReporter.start! conf
    end
  end

  it { should delegate :stop!, to: InfluxReporter }

  describe "when Opbeat is started", start: true do
    it { should be_started }

    it { should delegate :transaction, to: InfluxReporter::Client.inst, args: ['Test', nil, nil] }
    it { should delegate :trace, to: InfluxReporter::Client.inst, args: ['test', nil, {}] }
    it { should delegate :report, to: InfluxReporter::Client.inst, args: [Exception.new, nil] }
    it { should delegate :set_context, to: InfluxReporter::Client.inst, args: [{}] }
    it { should delegate :with_context, to: InfluxReporter::Client.inst, args: [{}] }
    it { should delegate :report_message, to: InfluxReporter::Client.inst, args: ["My message", nil] }
    it { should delegate :release, to: InfluxReporter::Client.inst, args: [{}, {}] }
    it { should delegate :capture, to: InfluxReporter::Client.inst }

    describe "a block example", mock_time: true do
      it "is done" do
        transaction = InfluxReporter.transaction 'Test' do
          travel 100
          InfluxReporter.trace 'test1' do
            travel 100
            InfluxReporter.trace 'test1-1' do
              travel 100
            end
            InfluxReporter.trace 'test1-2' do
              travel 100
            end
            travel 100
          end
        end.done(true)

        expect(transaction).to be_done
        expect(transaction.duration).to eq 500_000_000
      end
    end
  end

end
