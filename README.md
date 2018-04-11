# Shirinji

Container manager for dependency injection in Ruby.

## Principles

Dependencies Injection is strongly connected with the IOC (inversion of controls) pattern. IOC is
often seen as a "Java thing" and tend to be rejected by Ruby community.

Yet, it's heavily used in javascript world and fit perfectly with prototyped language.

```javascript
function updateUI(evt) { /* ... */ }

$.ajax('/action', { onSuccess: updateUI, ... })
```

A simple script like that is very common in Javascript and nobody is shocked by that. Yet, it's 
using the IOC pattern. The `$.ajax` method is delegating the action to perform when the request 
is successful to something else, focusing only on handling the http communication part.

Dependencies injection is nothing more than the exact same principle but applied to objects instead 
of functions.

Let's follow an example step by step from "the rails way" to a proper way to understand it better.

```ruby
class User < ActiveRecord::Base
  after_create :publish_statistics, :send_confirmation_email
  
  private
  
  def publish_statistics
    StatisticsGateway.publish_event(:new_user, user.id)
  end
  
  def send_confirmation_email
    UserMailer.confirm_email(user).deliver
  end
end
```

This is called "the rails way" and everybody with a tiny bit of experience knows that this way
is not valid. Your model is gonna send statistics and emails each time it's saved, even when it's
not in the context of signing up a new user (confusion between sign up, a business level operation 
and create, a persistency level operation). There are plenty of situation where you actually don't
want those operations to be performed (db seeding, imports, fixtures in tests ...)

That's where services pattern comes to the rescue. Let's do it in a very simple fashion and just 
move everything "as it is" in a service. 

```ruby
class SignUpUserService
  def call(user)
    user.signed_up_at = Time.now
    user.save!
    StatisticsGateway.publish_event(:new_user, user.id)
    UserMailer.confirm_email(user).deliver  
  end
end

## test

RSpec.describe SignUpUserService do
  let(:service) { described_class.new }
  
  describe '.call' do
    let(:message_instance) { double(deliver: nil) }
    let(:user) { FactoryGirl.build_stubbed(:user, id: 1) }
  
    before do
      allow(StatisticsGateway).to receive(:publish_event)
      allow(UserMailer).to receive(:confirm_email).and_return(message_instance) 
    end
    
    it 'saves user' do
      expect(user).to receive(:save!)
      
      service.call(user)
    end
    
    it 'sets signed up time' do
      service.call(user)
      expect(user.signed_up_at).to_not be_nil
      # there are better ways to test that but we don't care here
    end
    
    it 'publishes statistics' do
      expect(StatisticsGateway).to receive(:publish_event).with(:new_user, 1)
      
      service.call(user)
    end
    
    it 'notifies user for identity confirmation' do
      expect(UserMailer).to receive(:confirm_email).with(user)
      expect(message_instance).to receive(:deliver)
      
      service.call(user)
    end
  end  
end
```

It's a bit better. Now when we want to write a user in DB, it's not acting as a signup regardless
the context. It will act as a sign up only when we call SignUpService.

Yet, if we look a the tests for this service, we have to mock `StatisticsGateway` and
`UserMailer` in order for the test to run properly. It means that we need a very precise knowledge
of the implementation, and we need to mock global static objects which can be a very big problem
(for example, if the same class is called twice in very different contexts in the same method)

Also, if we decide to switch our statistics solution, or if we decide to change the way we notify
users for identity confirmation, our test for signing up a user will have to change. 
It shouldn't. The way we sign up users should not change according to the solution we chose to 
send emails. 

This demonstrate that our object has too many responsibilities. If you want to write efficient, 
fast, scalable, readable ... code, you should restrict your objects to one and only one responsbility.

```ruby
class SignUpUserService
  def call(user)
    user.signed_up_at = Time.now
    user.save!
    
    PublishUserStatisticsService.new.call(user)
    SendUserEmailConfirmationService.new.call(user)
    # implementation omitted for those services, you can figure it out  
  end
end
```

Now, our service has fewer responsibilities BUT, testing will be even harder because mocking `new`
method on both "sub services" will be even more dirty than before.
We can solve this problem very easily

```ruby
class SignUpUserService
  def call(user)
    user.signed_up_at = Time.now
    user.save!
    
    publish_user_statistics_service.call(user)
    send_user_email_confirmation_service.call(user)
  end
    
  private
  
  def publish_user_statistics_service
    PublishUserStatisticsService.new
  end
  
  def send_user_email_confirmation_service
    SendUserEmailConfirmationService.new
  end
end

## test

RSpec.describe SignUpUserService do
  let(:publish_statistics_service) { double(call: nil) }
  let(:send_email_confirmation_service) { double(call: nil) }
  
  let(:service) { described_class.new }
  
  before do
    allow(service).to receive(:publish_user_statistics_service).and_return(publish_statistics_service)
    allow(service).to receive(:send_user_email_confirmation_service).and_return(send_email_confirmation_service)
  end
  
  # ...
end
```

Our tests are now much easier to write. They're also much faster because our test is very specialized
and focus only on the service itself.
But if you think about it, this service still has too many responsibilities. It still carrying the 
responsibility of choosing which service will execute the "sub tasks" and more important, it's in
charge of creating those services instances.

Instead of having strong dependencies to other services, we can make them "weak" and increase our
code flexibility if we want to reuse it in another project.

```ruby
class SignUpUserService
  attr_reader :publish_user_statistics_service,
              :send_user_email_confirmation_service
              
  def initialize(
    publish_user_statistics_service:,
    send_user_email_confirmation_service:, 
  )
    @publish_user_statistics_service = publish_user_statistics_service
    @send_user_email_confirmation_service = send_user_email_confirmation_service
  end

  def call(user)
    user.signed_up_at = Time.now
    user.save!
    
    publish_user_statistics_service.call(user)
    send_user_email_confirmation_service.call(user)
  end
end
```

Now our service is completely agnostic about which solution is used to perform the "sub tasks".
It's the responsibility of it's environment to provide this information. 

But in a real world example, building such a tree is a complete nightmare and impossible to
maintain. It's where Shiringji comes to the rescue.  

## Usage

```ruby
map = Shirinji::Map.new do
  bean(:sign_up_user_service, klass: "SignUpUserService")
  bean(:publish_user_statistics_service, klass: "PublishUserStatisticsService")
  bean(:send_user_email_confirmation_service, klass: "SendUserEmailConfirmationService")
end

resolver = Shirinji::Resolver.new(map)

resolver.resolve(:sign_up_user_service)
#=> <#SignUpUserService @publish_user_statistics_service=<#PublishUserStatisticsService ...> ...> 
```

In this example, because `SingUpUserService` constructor parameters match beans with the same name,
Shirinji will automatically resolve them. 

In a case where a parameter name match no bean, it has to be mapped explicitly.

```ruby
map = Shirinji::Map.new do
  bean(:sign_up_user_service, klass: "SignUpUserService") do
    attr :publish_user_statistics_service, ref: :user_publish_statistics_service
  end
  
  # note the name is different
  bean(:user_publish_statistics_service, klass: "PublishUserStatisticsService")
  bean(:send_user_email_confirmation_service, klass: "SendUserEmailConfirmationService")
end

resolver = Shirinji::Resolver.new(map)

resolver.resolve(:sign_up_user_service)
#=> <#SignUpUserService @publish_user_statistics_service=<#PublishUserStatisticsService ...> ...> 
```

Shirinji provides scopes to help you organize your dependencies

```ruby
map = Shirinji::Map.new do
  scope module: :Services, suffix: :service, klass_suffix: :Service do
    scope module: :User, prefix: :user do
      bean(:signup, klass: 'Signup')
    end
  end
  
  # is the same as
  bean(:user_signup_service, klass: 'Services::User::SignupService') 
end
```

If you need a dependency to return a class instead of an instance, you can disable
the bean construction

```ruby
map = Shirinji::Map.new do
  bean(:foo, klass: 'Foo', construct: false)
end

resolver.resolve(:foo) #=> Foo 
```

Shirinji also provide a caching mecanism to achieve singleton pattern without having to implement
the pattern in your classes. It means the same class can be used as a singleton AND a regular class 
at the same time without any code change.

Singleton is the default access mode for a bean.

```ruby
map = Shirinji::Map.new do
  bean(:foo, klass: 'Foo', access: :singleton) # foo is singleton
  bean(:bar, klass: 'Bar', access: :instance) # bar is not
end

resolver = Shirinji::Resolver.new(map)

resolver.resolve(:foo).object_id #=> 1
resolver.resolve(:foo).object_id #=> 1

resolver.resolve(:bar).object_id #=> 2 
resolver.resolve(:bar).object_id #=> 3 
```

You can also create beans that contain single values. It will help you to avoid referencing global 
variables in your code.

```ruby
map = Shirinji::Map.new do
  bean(:config, value: Proc.new { Application.config })
  bean(:foo, klass: 'Foo')
end

resolver = Shirinji::Resolver.new(map)

class Foo
  attr_reader :config
  
  def initialize(config:)
    @config = config
  end
end

resolver.resolve(:foo)
#=> <#Foo @config=<#OpenStruct ...> ...>
```

Values can be anything. A `Proc` will be lazily evaluated. They also obey the singleton / instance
strategy.

## Notes

- It is absolutely mandatory for your beans to be stateless to use the singleton mode. If they're
  not, you will probably run into trouble as your objects behavior will depend on their history, leading
  to unpredictable effects.
- Shirinji only works with named arguments. It will raise errors if you try to use it with "standard"
  method arguments.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fdutey/shirinji.
