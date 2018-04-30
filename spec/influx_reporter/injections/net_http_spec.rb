# frozen_string_literal: true

require 'spec_helper'

require 'open-uri'

module InfluxReporter
  RSpec.describe 'net/http integration', start_without_worker: true do
    it 'is installed' do
      reg = InfluxReporter::Injections.installed['Net::HTTP']
      expect(reg).to_not be_nil
    end

    it 'traces http calls' do
      InfluxReporter::Injections.installed['Net::HTTP'].install

      WebMock.stub_request :get, 'http://example.com:80'

      transaction = InfluxReporter.transaction 'Test'

      Net::HTTP.start('example.com') do |http|
        http.get '/'
      end

      expect(WebMock).to have_requested(:get, 'http://example.com')
      expect(transaction.traces.length).to be 2

      http_trace = transaction.traces.last
      expect(http_trace.signature).to eq 'example.com'
      expect(http_trace.extra).to eq(tags: { scheme: 'http', port: 80, method: 'GET' },
                                     values: { path: '/' }
                                     )
    end
  end
end
