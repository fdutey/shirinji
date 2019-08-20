# frozen_string_literal: true

module Shirinji
  class Scope
    VALID_OPTIONS = %i[module prefix suffix klass_suffix auto_klass].freeze

    attr_reader :parent, :mod, :prefix, :suffix, :klass_suffix, :auto_klass

    def initialize(parent, **options, &block)
      validate_options(options)

      @parent = parent
      @mod = options[:module]
      @prefix = options[:prefix]
      @suffix = options[:suffix]
      @klass_suffix = options[:klass_suffix]
      @auto_klass = options[:auto_klass]

      instance_eval(&block) if block
    end

    def bean(name, klass: nil, **options, &block)
      klass ||= camelcase(name) if !options[:value] && auto_klass
      chunks = [mod, "#{klass}#{klass_suffix}"].compact
      options = options.merge(klass: klass ? chunks.join('::') : nil)

      scoped_name = [prefix, name, suffix].compact.join('_')

      parent.bean(scoped_name, **options, &block)
    end

    def scope(**options, &block)
      opts = { auto_klass: auto_klass }.merge(options)

      Scope.new(self, **opts, &block)
    end

    private

    def camelcase(str)
      chunks = str.to_s.split('_').map do |w|
        w = w.downcase
        w[0] = w[0].upcase
        w
      end

      chunks.join
    end

    def validate_options(args)
      args.each_key do |k|
        next if Shirinji::Scope::VALID_OPTIONS.include?(k)

        raise ArgumentError, "Unknown key #{k}"
      end
    end
  end
end
