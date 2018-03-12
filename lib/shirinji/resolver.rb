# frozen_string_literal: true

module Shirinji
  class Resolver
    ARG_TYPES = %i[key keyreq].freeze

    attr_reader :map, :singletons

    def initialize(map)
      @map = map
      @singletons = {}
    end

    def resolve(name)
      bean = map.get(name)

      if bean.access == :singleton
        single = singletons[name]
        return single if single
      end

      resolve_bean(bean).tap do |instance|
        singletons[name] = instance if bean.access == :singleton
      end
    end

    def reset_cache
      @singletons = {}
    end

    private

    def resolve_bean(bean)
      send(:"resolve_#{bean.value ? :value : :class}_bean", bean)
    end

    def resolve_value_bean(bean)
      bean.value.is_a?(Proc) ? bean.value.call : bean.value
    end

    def resolve_class_bean(bean)
      klass, params = resolve_class(bean)
      return klass.new if params.empty?

      check_params!(params)

      args = params.each_with_object({}) do |(_type, arg), memo|
        memo[arg] = resolve(resolve_attribute(bean, arg))
      end

      klass.new(**args)
    end

    def resolve_class(bean)
      klass = bean.class_name.constantize
      construct = klass.instance_method(:initialize)

      [klass, construct.parameters]
    end

    def resolve_attribute(bean, arg)
      (attr = bean.attributes[arg]) ? attr.reference : arg
    end

    def check_params!(params)
      params.each do |pair|
        next if ARG_TYPES.include?(pair.first)
        raise ArgumentError, 'Only key arguments are allowed'
      end
    end
  end
end
