# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Shirinji::Utils::String do
  describe '.camelcase' do
    it 'turns an underscore string into upper camel case' do
      expect(described_class.camelcase('foo_bar')).to eq('FooBar')
    end
  end

  describe '.snakecase' do
    it 'turns a camelcase string into a snake case on' do
      expect(described_class.snakecase('FooBar42')).to eq('foo_bar_42')
    end
  end
end
