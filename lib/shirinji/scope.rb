# frozen_string_literal: true

module Shirinji
  class Scope
    VALID_OPTIONS = %i[module prefix suffix klass_suffix].freeze

    attr_reader :parent, :mod, :prefix, :suffix, :klass_suffix

    def initialize(parent, **options, &block)
      validate_options(options)

      @parent = parent
      @mod = options[:module]
      @prefix = options[:prefix]
      @suffix = options[:suffix]
      @klass_suffix = options[:klass_suffix]

      instance_eval(&block) if block
    end

    def bean(name, klass: nil, value: nil, access: :singleton, &block)
      chunks = [mod, "#{klass}#{klass_suffix}"].compact
      options = {
        access: access,
        klass: klass ? chunks.join('::') : nil,
        value: value
      }

      parent.bean([prefix, name, suffix].compact.join('_'), **options, &block)
    end

    def scope(**options, &block)
      Scope.new(self, **options, &block)
    end

    private

    def validate_options(args)
      args.each_key do |k|
        next if Shirinji::Scope::VALID_OPTIONS.include?(k)
        raise ArgumentError, "Unknown key #{k}"
      end
    end
  end
end
