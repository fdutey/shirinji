# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Shirinji::Utils::String do
  describe '.camelcase' do
    it 'turn an underscore string into upper camel case' do
      expect(described_class.camelcase('foo_bar')).to eq('FooBar')
    end
  end
end
