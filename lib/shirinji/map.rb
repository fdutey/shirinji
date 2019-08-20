# frozen_string_literal: true

module Shirinji
  class Map
    attr_reader :beans

    # Loads a map at a given location
    #
    # @param location [string] path to the map to load
    def self.load(location)
      eval(File.read(location))
    end

    def initialize(&block)
      @beans = {}

      instance_eval(&block) if block
    end

    # Merges another map at a given location
    #
    # @param location [string] the file to include - must be an absolute path
    def include_map(location)
      merge(self.class.load(location))
    end

    # Merges a map into another one
    #
    # @param map [Shirinji::Map] the map to merge into this one
    # @raise [ArgumentError] if both map contains a bean with the same bean
    def merge(map)
      map.beans.keys.each { |name| raise_if_name_already_taken!(name) }

      beans.merge!(map.beans)
    end

    # Returns a bean based on its name
    #
    # @example accessing a bean
    #   map.get(:foo)
    #   #=> <#Shirinji::Bean ....>
    #
    # @example accessing a bean that doesn't exist
    #   map.get(:bar)
    #   #=> raises ArgumentError (unknown bean)
    #
    # @param name [Symbol, String] the name of the bean you want to access to
    # @return [Bean] A bean with the given name or raises an error
    # @raise [ArgumentError] if trying to access a bean that doesn't exist
    def get(name)
      bean = beans[name.to_sym]
      raise ArgumentError, "Unknown bean #{name}" unless bean

      bean
    end

    # Add a bean to the map
    #
    # @example build a class bean
    #   map.bean(:foo, klass: 'Foo', access: :singleton)
    #
    # @example build a class bean with attributes
    #   map.bean(:foo, klass: 'Foo', access: :singleton) do
    #     attr :bar, ref: :baz
    #   end
    #
    # @example build a value bean
    #   map.bean(:bar, value: 5)
    #
    # @example build a lazy evaluated value bean
    #   map.bean(:bar, value: Proc.new { 5 })
    #
    # @param name [Symbol] the name you want to register your bean
    # @option [String] :klass the classname the bean is registering
    # @option [Object] :value the object registered by the bean
    # @option [Boolean] :construct whether the bean should be constructed or not
    # @option [Symbol] :access either :singleton or :instance.
    # @yield additional method to construct our bean
    # @raise [ArgumentError] if trying to register a bean that already exist
    def bean(name, klass: nil, access: :singleton, **others, &block)
      name = name.to_sym

      raise_if_name_already_taken!(name)

      options = others.merge(
        access: access,
        class_name: klass&.freeze
      )

      beans[name] = Bean.new(name, **options, &block)
    end

    # Scopes a given set of bean to the default options
    #
    # @example module
    #   scope(module: :Foo) do
    #     bean(:bar, klass: 'Bar')
    #   end
    #
    #   #=> bean(:bar, klass: 'Foo::Bar')
    #
    # @example prefix
    #   scope(prefix: :foo) do
    #     bean(:bar, klass: 'Bar')
    #   end
    #
    #   #=> bean(:foo_bar, klass: 'Bar')
    #
    # @example suffix
    #   scope(suffix: :bar) do
    #     bean(:foo, klass: 'Foo')
    #   end
    #
    #   #=> bean(:foo_bar, klass: 'Foo')
    #
    # @example class suffix
    #   scope(klass_suffix: :Bar) do
    #     bean(:foo, klass: 'Foo')
    #   end
    #
    #   #=> bean(:foo, klass: 'FooBar')
    #
    # It comes pretty handy when used with strongly normative naming
    #
    # @example services
    #   scope(module: :Services, klass_suffix: :Service, suffix: :service) do
    #     scope(module: :User, prefix: :user) do
    #       bean(:signup, klass: 'Signup')
    #       bean(:ban, klass: 'Ban')
    #     end
    #   end
    #
    #   #=> bean(:user_signup_service, klass: 'Services::User::SignupService')
    #   #=> bean(:user_ban_service, klass: 'Services::User::BanService')
    #
    # @param options [Hash]
    # @option options [Symbol] :module prepend module name to class name
    # @option options [Symbol] :prefix prepend prefix to bean name
    # @option options [Symbol] :suffix append suffix to bean name
    # @option options [Symbol] :klass_suffix append suffix to class name
    # @yield a standard map
    def scope(**options, &block)
      Scope.new(self, **options, &block)
    end

    private

    def raise_if_name_already_taken!(name)
      return unless beans[name]

      msg = "A bean already exists with the following name: #{name}"
      raise ArgumentError, msg
    end
  end
end
