require 'spec_helper'
require 'sinatra'

module InfluxReporter
  RSpec.describe Injections::Sinatra do

    it "is installed" do
      reg = InfluxReporter::Injections.installed['Sinatra::Base']
      expect(reg).to_not be_nil
    end

  end
end
