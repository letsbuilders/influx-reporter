# frozen_string_literal: true

require 'spec_helper'

module InfluxReporter
  RSpec.describe Client do
    let(:config) { Configuration.new influx_db: { host: :localhost }}

    describe '.start!' do
      it "set's up an instance and only one" do
        first_instance = Client.start! config
        expect(Client.inst).to_not be_nil
        expect(Client.start!(config)).to be first_instance
      end
    end

    describe '.stop!' do
      it 'kills the instance but flushes before' do
        Client.start! config
        Client.inst.submit_transaction Transaction.new(Client.inst, 'Test').done(200)
        Client.stop!
        expect(WebMock).to have_requested(:post, %r{\/write})
        expect(Client.inst).to be_nil
      end
    end

    context 'without worker spec setting', start_without_worker: true do
      it "doesn't start a Worker" do
        expect(Thread).to_not receive(:new)
        Client.start! config
        expect(Client.inst).to_not be_nil
      end
    end

    context 'with a running client', start_without_worker: true do
      subject { Client.inst }

      describe '#transaction' do
        it 'returns a new transaction and sets it as current' do
          transaction = subject.transaction 'Test'
          expect(transaction).to_not be_nil
          expect(subject.current_transaction).to be transaction
        end
        it 'returns the current transaction if present' do
          transaction = subject.transaction 'Test'
          expect(subject.transaction('Test')).to eq transaction
        end
        context 'with a block' do
          it 'yields transaction' do
            blck = ->(*args) {}
            allow(blck).to receive(:call)
            subject.transaction('Test') { |t| blck.call(t) }
            expect(blck).to have_received(:call).with(Transaction)
          end
          it 'returns transaction' do
            result = subject.transaction('Test') { "DON'T RETURN ME" }
            expect(result).to be_a Transaction
          end
        end
      end

      describe '#trace' do
        it 'delegates to current transaction' do
          subject.current_transaction = double('transaction', trace: true)
          subject.trace 1, 2, 3
          expect(subject.current_transaction).to have_received(:trace).with(1, 2, 3)
          subject.current_transaction = nil
        end

        it 'ignores when outside transaction' do
          blk = proc {}
          allow(blk).to receive(:call)
          subject.trace { blk.call }
          expect(blk).to have_received(:call)
        end
      end

      describe '#submit_transaction' do
        it "doesn't send right away" do
          transaction = Transaction.new(subject, 'test')

          subject.submit_transaction transaction

          expect(subject.queue.length).to be 0
          expect(WebMock).to_not have_requested(:post, %r{/transactions/$})
        end

        it "sends if it's long enough ago that we sent last" do
          transaction = Transaction.new(subject, 'test')
          subject.instance_variable_set :@last_sent_transactions, Time.now.utc - 61

          subject.submit_transaction transaction

          expect(subject.queue.length).to be 1
          expect(subject.queue.pop).to be_a Worker::PostRequest
        end

        it 'sends if interval is disabled' do
          transaction = Transaction.new(subject, 'test')
          subject.config.transaction_post_interval = nil
          subject.submit_transaction transaction
          expect(subject.queue.length).to be 1
        end
      end

      describe '#set_context' do
        it 'sets context for future errors' do
          subject.set_context(tags: { additional_information: 'remember me' })

          exception = Exception.new('BOOM')
          subject.report exception

          expect(subject.queue.length).to be 1
          expect(subject.queue.pop.data[:tags][:additional_information]).to eq('remember me')
        end
      end

      describe '#with_context' do
        it 'sets context for future errors' do
          subject.with_context(tags: { additional_information: 'remember me' }) do
            exception = Exception.new('BOOM')
            subject.report exception
          end

          expect(subject.queue.length).to be 1
          expect(subject.queue.pop.data[:tags][:additional_information]).to eq('remember me')
        end

        it 'supports nested contexts' do
          subject.with_context(values: { info: 'a' }) do
            subject.with_context(values: { more_info: 'b' }) do
              exception = Exception.new('BOOM')
              subject.report exception
            end
          end

          expect(subject.queue.length).to be 1
          data = subject.queue.pop.data
          expect(data[:values][:info]).to eq('a')
          expect(data[:values][:more_info]).to eq('b')
        end

        it 'restores context for future errors' do
          subject.set_context(values: { info: 'hello' })

          subject.with_context(values: { additional_information: 'remember me' }) do
          end

          exception = Exception.new('BOOM')
          subject.report exception

          expect(subject.queue.length).to be 1
          data = subject.queue.pop.data
          expect(data[:values][:info]).to eq('hello')
          expect(data[:values][:additional_information]).not_to be
        end

        it 'returns what is yielded' do
          result = subject.with_context(additional_information: 'remember me') do
            42
          end

          expect(result).to be 42
        end
      end

      describe '#report' do
        it 'builds and posts an exception' do
          exception = Exception.new('BOOM')

          subject.report exception

          expect(subject.queue.length).to be 1
          expect(subject.queue.pop).to be_a Worker::PostRequest
        end

        it 'skips nil exceptions' do
          subject.report nil
          expect(WebMock).to_not have_requested(:post, %r{/errors/$})
        end
      end

      describe '#report_message' do
        it 'builds and posts an exception' do
          subject.report_message 'Massage message'

          expect(subject.queue.length).to be 1
          expect(subject.queue.pop).to be_a Worker::PostRequest
        end
      end

      describe '#capture' do
        it 'captures exceptions and sends them off then raises them again' do
          exception = Exception.new('BOOM')

          expect do
            subject.capture do
              raise exception
            end
          end.to raise_exception(Exception)

          expect(subject.queue.length).to be 1
          expect(subject.queue.pop).to be_a Worker::PostRequest
        end
      end
    end

    context 'with performance disabled' do
      subject do
        InfluxReporter::Client.inst
      end

      before do
        config.disable_performance = true
        InfluxReporter.start! config
      end
      after { InfluxReporter.stop! }

      describe '#transaction' do
        it 'yields' do
          block = -> {}
          expect(block).to receive(:call)
          Client.inst.transaction('Test') { block.call }
        end
        it 'returns nil' do
          expect(Client.inst.transaction('Test')).to be_nil
        end
      end

      describe '#trace' do
        it 'yields' do
          block = -> {}
          expect(block).to receive(:call)
          Client.inst.trace('Test', 'trace') { block.call }
        end
        it 'returns nil' do
          expect(Client.inst.trace('Test', 'test')).to be_nil
        end
      end
    end

    context 'with errors disabled' do
      subject do
        InfluxReporter::Client.inst
      end

      before do
        config.disable_errors = true
        InfluxReporter.start! config
      end
      after { InfluxReporter.stop! }

      describe '#report' do
        it "doesn't do anything" do
          exception = Exception.new('BOOM')

          Client.inst.report exception

          expect(Client.inst.queue.length).to be 0
        end
      end
    end
  end
end
