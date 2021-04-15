# Shirinji

[![Gem Version](https://badge.fury.io/rb/shirinji.svg)](
https://badge.fury.io/rb/shirinji
)
[![Build Status](https://travis-ci.org/fdutey/shirinji.svg?branch=master)](
https://travis-ci.org/fdutey/shirinji
)
[![Maintainability](
https://api.codeclimate.com/v1/badges/4b1c0010788d70581680/maintainability)
](https://codeclimate.com/github/fdutey/shirinji/maintainability)

Dependencies Injection made clean and easy for Ruby.

## Supported ruby versions

- 2.4.x
- 2.5.x
- 2.6.x
- 2.7.x
- 3.0.x

## Principles

Remove hard dependencies between your objects and delegate object tree building
to an unobtrusive framework with cool convention over configuration. 

Shirinji relies on a mapping of beans and a resolver. When you resolve a bean,
it will return (by default) an instance of the class associated to the bean,
with all the bean dependencies resolved.

```ruby
class FooService
  attr_reader :bar_service
  
  def initialize(bar_service:)
    @bar_service = bar_service
  end
  
  def call(obj)
    obj.foo = 123
    
    bar_service.call(obj)
  end
end

map = Shirinji::Map.new do
  bean(:foo_service, klass: 'FooService')
  bean(:bar_service, klass: 'BarService')
end

resolver = Shirinji::Resolver.new(map)

resolver.resolve(:foo_service)
# => <#FooService @bar_service=<#BarService>> 
```

Shirinji is unobtrusive. Basically, any of your objects can be used 
outside of its context.

```ruby
bar_service = BarService.new
foo_service = FooService.new(bar_service: bar_service)
# => <#FooService @bar_service=<#BarService>>

# tests

RSpec.describe FooService do
  let(:bar_service) { double(call: nil) }
  let(:service) { described_class.new(bar_service: bar_service) }
  
  describe '.call' do
    # ...
  end
end
```

## Constructor arguments

Shirinji relies on constructor to inject dependencies. It's considering that
objects that receive dependencies should be immutables and those dependencies
should not change during your program lifecycle.

Shirinji doesn't accept anything else than named parameters. This way,
arguments order doesn't matter and it makes everybody's life easier. 

## Name resolution

By default, when you try to resolve a bean, Shirinji will look for a bean named 
accordingly for each constructor parameter. 

It's possible to locally override this behaviour though by using `attr` macro.

```ruby
class FooService
  attr_reader :bar_service
  
  def initialize(my_service:)
    @bar_service = my_service
  end
end

map = Shirinji::Map.new do
  bean(:foo_service, klass: 'FooService') do
    attr :my_service, ref: :bar_service
  end
  
  bean(:bar_service, klass: 'BarService')
end

resolver = Shirinji::Resolver.new(map)

resolver.resolve(:foo_service)
# => <#FooService @bar_service=<#BarService>>
```

## Caching and singletons

Shirinji provides a caching mecanism to help you improve memory consumption.
This cache is safe as long as your beans remains immutable (they should always
be). 

The consequence is that any cached instance is actually a singleton. Singleton
is no more a property of your class but of it's environment, improving the
reusability of your code. 

Singleton is the default access mode for a bean.

```ruby
map = Shirinji::Map.new do
  bean(:bar_service, klass: 'BarService', access: :instance)
  bean(:foo_service, klass: 'FooService', access: :singleton)
  # same as bean(:foo_service, klass: 'FooService')
end

resolver = Shirinji::Resolver.new(map)

resolver.resolve(:foo_service).object_id #=> 1
resolver.resolve(:foo_service).object_id #=> 1

resolver.resolve(:bar_service).object_id #=> 2 
resolver.resolve(:bar_service).object_id #=> 3 
```

Cache can be reset with the simple command `resolver.reset_cache`, which can be
useful when using a development console like rails console ([shirinji-rails](
https://github.com/fdutey/shirinji-rails) is attaching cache reset to `reload!` 
command).

## Other type of beans

Dependencies injection doesn't apply only to classes. You can actually inject
anything and therefore, Shirinji allows you to declare anything as a dependency.
To achieve that, use the key `value` instead of `class`.

```ruby
module MyApp
  def self.config
    @config
  end
  
  def self.load!
    @config = OpenStruct.new  
  end
end

class FooService
  attr_reader :config
  
  def initialize(config:)
    @config = config
  end
end

MyApp.load!

map = Shirinji::Map.new do
  bean(:config, value: Proc.new { MyApp.config })
  
  bean(:foo_service, klass: 'FooService')
end

resolver = Shirinji::Resolver.new(map)

resolver.resolve(:foo_service)
#=> <#FooService @config=<#OpenStruct ...> ...>
```

A value can be anything. `Proc` will be lazily evaluated. It also obeys the 
cache mechanism described before.

## Skip construction mechanism

In some cases, you need a dependency to be injected as a class and not an 
instance. In such case, you could use value beans, returning the class itself, 
but you would lose the benefit of scopes (see below). 
Instead, Shirinji provides a parameter to skip the object construction.

A real life example is a Job where `deliver_now` and `deliver_later` are 
class methods.

```ruby
map = Shirinji::Map.new do
  bean(:foo_job, klass: 'FooJob', construct: false)
end

resolver = Shirinji::Resolver.new(map)

resolver.resolve(:foo_job) #=> FooJob
```

## Scopes

Building complex objects mapping leads to lot of repetition. That's why Shirinji 
also provides a scope mechanism to help you dry your code.

```ruby
map = Shirinji::Map.new do
  scope module: :Services, suffix: :service, klass_suffix: :Service do
    bean(:foo, klass: 'Foo')
    # same as bean(:foo_service, klass: 'Services::FooService')
    
    scope module: :User, prefix: :user do
      bean(:bar, klass: 'Bar')
      # same as bean(:user_bar_service, klass: 'Services::User::BarService')
    end 
  end
end
```

Scopes also come with an `auto_klass` attribute to save even more time for 
common cases

```ruby
map = Shirinji::Map.new do
  scope module: :Services, 
        suffix: :service, 
        klass_suffix: :Service, 
        auto_klass: true do
    bean(:foo)
    # same as bean(:foo_service, klass: 'Services::FooService')
  end
end
```

Scopes also provides an `auto_prefix` option

```ruby
map = Shirinji::Map.new do
  scope module: :Services, 
        suffix: :service, 
        klass_suffix: :Service, 
        auto_klass: true do
        
    # Do not use auto prefix on root scope or every bean will be prefixed
    # with `services_`
    scope auto_prefix: true do
      bean(:foo)
      # same as bean(:foo_service, klass: 'Services::FooService')
      
      scope module: :User do
        # same as scope module: :User, prefix: :user
  
        bean(:bar)
        # same as bean(:user_bar_service, klass: 'Services::User::BarService')
      end
    end
  end
end
```

Finally, for mailers / jobs ..., Scopes allow you to specify a global value
for `construct`

```ruby
map = Shirinji::Map.new do
  scope module: :Jobs, 
        suffix: :job, 
        klass_suffix: :Job, 
        auto_klass: true, 
        construct: false do
    bean(:foo)
    # bean(:foo_job, klass: 'Jobs::FooJob', construct: false)
  end
end
```

Scopes do not carry property `access`

## Code splitting

When a project grows, dependencies grows too. Keeping them into one single file
leads to headaches. One possible solution to keep everything under control is
to split your dependencies into many files.

To include a "sub-map" into another one, you can use `include_map` method.

```ruby
# dependencies/services.rb
Shirinji::Map.new do
  bean(:foo_service, klass: 'FooService')
end

# dependencies/queries.rb
Shirinji::Map.new do
  bean(:foo_query, klass: 'FooQuery')
end

# dependencies.rb

root = Pathname.new(File.expand_path('../dependencies', __FILE__))

Shirinji::Map.new do
  bean(:config, value: -> { MyApp.config })
  
  # paths must be absolute 
  include_map(root.join('queries.rb'))
  include_map(root.join('services.rb'))
end
```

## Notes

- It is absolutely mandatory for your beans to be stateless to use the singleton 
  mode. If they're not, you will probably run into trouble as your objects 
  behavior will depend on their history, leading to unpredictable effects.
- Shirinji only works with named arguments. It will raise `ArgumentError` if you 
  try to use it with "standard" method arguments.
  
## TODOS

- solve absolute paths problems for `include_map` (`instance_eval` is a problem)

## Contributing

Bug reports and pull requests are welcome on GitHub at 
https://github.com/fdutey/shirinji.
