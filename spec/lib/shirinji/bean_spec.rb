# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Shirinji::Bean do
  describe '.new' do
    context 'with value' do
      it 'is valid' do
        expect {
          described_class.new(:test, value: 1, access: :singleton)
        }.to_not raise_error
      end
    end

    context 'with class name' do
      it 'is valid' do
        expect {
          described_class.new(:test, class_name: 'a', access: :singleton)
        }.to_not raise_error
      end
    end

    context 'without value nor class name' do
      it 'raises ArgumentError' do
        expect {
          described_class.new(:test, access: :singleton)
        }.to raise_error(ArgumentError)
      end
    end

    context 'with both value and class name' do
      it 'raises ArgumentError' do
        expect {
          described_class.new(:test, value: 1, class_name: 'a', access: :singleton)
        }.to raise_error(ArgumentError)
      end
    end
  end
end
