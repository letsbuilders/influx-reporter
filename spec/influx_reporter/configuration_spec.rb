# frozen_string_literal: true

require 'spec_helper'

module InfluxReporter
  RSpec.describe Configuration do
    it 'has defaults' do
      conf = Configuration.new
      expect(conf.timeout).to be 100
      expect(conf.filter_parameters).to eq [/(authorization|password|passwd|secret)/i]
    end

    it 'overwrites defaults when config given' do
      conf = Configuration.new(filter_parameters: [:secret])
      expect(conf.timeout).to be 100
      expect(conf.filter_parameters).to eq [:secret]
    end

    it 'can initialize with a hash' do
      conf = Configuration.new timeout: 1000
      expect(conf.timeout).to be 1000
    end

    it 'yields itself to a given block' do
      conf = Configuration.new do |c|
        c.timeout = 1000
      end
      expect(conf.timeout).to be 1000
    end

    describe '#validate' do
      let(:auth_opts) { { database: 'endpoints' } }
      it 'is true when all auth options are set' do
        expect(Configuration.new(auth_opts).validate!).to be true
      end

      it 'is true' do
        expect(Configuration.new(auth_opts).validate!).to be true
      end
    end
  end
end
