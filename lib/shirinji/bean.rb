# frozen_string_literal: true

module Shirinji
  class Bean
    attr_reader :name, :class_name, :value, :access, :attributes, :construct

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      name, class_name: nil, value: nil, access:, construct: true, &block
    )
      check_params!(class_name, value)

      @name = name
      @class_name = class_name
      @value = value
      @access = access
      @attributes = {}
      @construct = construct

      instance_eval(&block) if block
    end
    # rubocop:enable Metrics/ParameterLists

    def attr(name, ref:)
      attributes[name] = Attribute.new(name, ref)
    end

    private

    def check_params!(class_name, value)
      msg = if class_name && value
              'you can use either `class_name` or `value` but not both'
            elsif !class_name && !value
              'you must pass either `class_name` or `value`'
            end

      raise ArgumentError, msg if msg
    end
  end
end
