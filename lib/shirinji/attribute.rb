# frozen_string_literal: true

module Shirinji
  class Attribute
    attr_reader :name, :reference

    def initialize(name, reference)
      @name = name
      @reference = reference
    end
  end
end
