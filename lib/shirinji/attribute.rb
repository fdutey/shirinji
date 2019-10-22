# frozen_string_literal: true

module Shirinji
  class Attribute
    attr_reader :name, :reference, :value

    def initialize(name, reference = nil, value = nil)
      @name = name
      @reference = reference
      @value = value
    end
  end
end
