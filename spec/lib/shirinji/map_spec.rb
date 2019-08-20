# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Shirinji::Map do
  let(:map) { described_class.new }

  describe '.bean' do
    it 'returns a new bean' do
      b = map.bean(:foo, klass: 'Foo')

      expect(b).to be_a(Shirinji::Bean)
      expect(b.name).to eq(:foo)
      expect(b.class_name).to eq('Foo')
      expect(b.access).to eq(:singleton)
    end

    it 'registers the bean in the map' do
      b = map.bean(:foo, klass: 'Foo')

      expect(map.beans[:foo]).to eq(b)
    end
  end
end
