# frozen_string_literal: true

require 'spec_helper'

module InfluxReporter
  RSpec.describe Normalizers do
    let(:config) { Configuration.new }

    describe Normalizers::Default do
      it 'skips' do
        normalizer = Normalizers::Default.new config
        expect(normalizer.normalize(1, 2, 3)).to eq :skip
      end
    end
  end
end
