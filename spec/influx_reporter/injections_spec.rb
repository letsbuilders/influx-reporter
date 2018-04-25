# frozen_string_literal: true

require 'spec_helper'

module InfluxReporter
  RSpec.describe Injections do
    class TestProbe
      def initialize
        @installations = 0
      end

      def install
        @installations += 1
      end
      attr_reader :installations
    end

    let(:probe) { TestProbe.new }
    subject { InfluxReporter::Injections }

    it 'installs right away if constant is defined' do
      subject.register 'Opbeat', 'influx_reporter', probe
      expect(probe.installations).to be 1
    end

    it 'installs a require hook' do
      subject.register 'SomeLib', 'influx_reporter', probe

      expect(probe.installations).to be 0

      class ::SomeLib; end
      require 'influx_reporter'
      expect(probe.installations).to be 1

      require 'influx_reporter'
      expect(probe.installations).to be 1
    end

    it "doesn't install something that never exists" do
      subject.register 'SomethingElse', 'wut', probe
      expect(probe.installations).to be 0
    end

    it "doesn't install when required but class is missing" do
      subject.register 'SomethingElse', 'influx_reporter', probe
      require 'influx_reporter'
      expect(probe.installations).to be 0
    end
  end
end
