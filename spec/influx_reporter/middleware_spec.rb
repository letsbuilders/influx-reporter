# frozen_string_literal: true

require 'spec_helper'
require 'influx_reporter'

module InfluxReporter
  describe Middleware, start_without_worker: true do
    it 'surrounds the request in a transaction' do
      app = Middleware.new(lambda do |_env|
        [200, {}, ['']]
      end)
      status, _, body = app.call(Rack::MockRequest.env_for('/'))
      body.close

      expect(status).to eq 200
      expect(InfluxReporter::Client.inst.pending_transactions.length).to be 1
      expect(InfluxReporter::Client.inst.current_transaction).to be_nil
    end

    it 'submits on exceptions' do
      app = Middleware.new(lambda do |_env|
        raise Exception, 'BOOM'
      end)

      expect { app.call(Rack::MockRequest.env_for('/')) }.to raise_error(Exception)
      expect(InfluxReporter::Client.inst.queue.length).to be 1
      expect(InfluxReporter::Client.inst.current_transaction).to be_nil

      expect(InfluxReporter::Client.inst.queue.length).to be 1
    end
  end
end
