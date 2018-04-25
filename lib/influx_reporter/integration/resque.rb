# frozen_string_literal: true

begin
  require 'resque'
rescue LoadError
end

if defined? Resque
  module InfluxReporter
    module Integration
      class Resque < Resque::Failure::Base
        def save
          InfluxReporter.report exception
        end
      end
    end
  end
end
