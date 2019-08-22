# frozen_string_literal: true

module Shirinji
  class Scope
    VALID_OPTIONS = %i[
      module prefix suffix klass_suffix auto_klass auto_prefix construct
    ].freeze

    attr_reader :parent, :mod, :prefix, :suffix, :klass_suffix, :auto_klass,
                :construct, :auto_prefix

    def initialize(parent, **options, &block)
      validate_options(options)

      @parent = parent
      @mod = options[:module]
      @suffix = options[:suffix]
      @klass_suffix = options[:klass_suffix]
      @auto_klass = options[:auto_klass]
      @auto_prefix = options[:auto_prefix]
      @prefix = generate_prefix(options[:prefix])
      @construct = options.fetch(:construct, true)

      instance_eval(&block) if block
    end

    def bean(name, klass: nil, **options, &block)
      default_opts = compact({ construct: construct })

      klass = generate_klass(name, klass) unless options[:value]
      options = compact(default_opts.merge(options).merge(klass: klass))
      scoped_name = generate_scope(name)

      parent.bean(scoped_name, **options, &block)
    end

    def scope(**options, &block)
      opts = {
        auto_klass: auto_klass,
        auto_prefix: auto_prefix,
        construct: construct
      }.merge(options)

      Scope.new(self, **opts, &block)
    end

    private

    def compact(h)
      h.reject { |_,v| v.nil? }
    end

    def generate_scope(name)
      [prefix, name, suffix].compact.join('_')
    end

    def generate_klass(name, klass)
      return if !klass && !auto_klass

      klass ||= klassify(name)
      chunks = [mod, "#{klass}#{klass_suffix}"].compact

      chunks.join('::')
    end

    def generate_prefix(prefix)
      return prefix if prefix
      return nil unless auto_prefix

      mod && underscore(mod.to_s).to_sym
    end

    def klassify(name)
      Shirinji::Utils::String.camelcase(name)
    end

    def underscore(name)
      Shirinji::Utils::String.snakecase(name)
    end

    def validate_options(args)
      args.each_key do |k|
        next if Shirinji::Scope::VALID_OPTIONS.include?(k)

        raise ArgumentError, "Unknown key #{k}"
      end
    end
  end
end
