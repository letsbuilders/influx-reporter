# frozen_string_literal: true

require 'spec_helper'
require 'sinatra'

module InfluxReporter
  RSpec.describe 'sinatra integration' do
    include Rack::Test::Methods

    def config
      @config ||= InfluxReporter::Configuration.new do |c|
        c.disable_worker = true
      end
    end

    around do |example|
      InfluxReporter.start! config
      example.call
      InfluxReporter.stop!
    end

    class TestApp < ::Sinatra::Base
      disable :show_exceptions
      use InfluxReporter::Middleware

      get '/' do
        erb 'I am an inline template!'
      end

      template :tmpl do
        'I am a template!'
      end

      get '/tmpl' do
        erb :tmpl
      end
    end

    def app
      TestApp
    end

    it 'wraps routes in transactions' do
      get '/'

      transaction = InfluxReporter::Client.inst.pending_transactions.last
      expect(transaction.endpoint).to eq 'GET /'
    end

    it 'traces templates' do
      get '/tmpl'

      transaction = InfluxReporter::Client.inst.pending_transactions.last
      expect(transaction.traces.last.signature).to eq 'tmpl'
    end

    it 'traces inline templates' do
      get '/'

      transaction = InfluxReporter::Client.inst.pending_transactions.last
      expect(transaction.traces.last.signature).to eq 'Inline erb'
    end
  end

  RSpec.describe 'sinatra integration without perfomance' do
    include Rack::Test::Methods

    def config
      @config ||= InfluxReporter::Configuration.new do |c|
        c.disable_worker = true
        c.disable_performance = true
      end
    end

    around do |example|
      InfluxReporter.start! config
      example.call
      InfluxReporter.stop!
    end

    class TestApp < ::Sinatra::Base
      disable :show_exceptions
      use InfluxReporter::Middleware

      get '/' do
        erb 'I am an inline template!'
      end
    end

    def app
      TestApp
    end

    it 'wraps routes in transactions' do
      get '/'
      expect(InfluxReporter::Client.inst.pending_transactions.last).to be_nil
    end
  end
end
