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

    def bean(name, klass: nil, **others, &block)
      chunks = [mod, "#{klass}#{klass_suffix}"].compact
      options = others.merge(klass: klass ? chunks.join('::') : nil)
      scoped_name = [prefix, name, suffix].compact.join('_')

      parent.bean(scoped_name, **options, &block)
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
