# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Shirinji::Resolver do
  let(:map) { double('map', get: bean) }
  let(:resolver) { described_class.new(map) }
  let(:instance) { double('instance') }

  describe '.resolve' do
    before do
      allow(resolver).to receive(:resolve_bean).and_return(instance)
    end

    context 'bean is a singleton' do
      let(:bean) { double('singleton bean', access: :singleton) }

      context 'bean is already cached' do
        before do
          resolver.instance_variable_set(:@singletons, foo: instance)
        end

        it 'does not try to resolve bean' do
          expect(resolver).to_not receive(:resolve_bean)
          resolver.resolve(:foo)
        end

        it 'returns the cached version' do
          expect(resolver.resolve(:foo)).to eq(instance)
        end
      end

      context 'bean is not cached' do
        it 'returns bean' do
          expect(resolver.resolve(:foo)).to eq(instance)
        end

        it 'resolves bean' do
          expect(resolver).to receive(:resolve_bean)
          resolver.resolve(:foo)
        end

        it 'caches bean' do
          expect {
            resolver.resolve(:foo)
          }.to change(resolver, :singletons).from({}).to(foo: instance)
        end
      end
    end

    context 'bean is not a singleton' do
      let(:bean) { double('not a singleton', access: :instance) }

      it 'resolves bean' do
        expect(resolver).to receive(:resolve_bean)
        resolver.resolve(:foo)
      end

      it 'returns instance' do
        expect(resolver.resolve(:foo)).to eq(instance)
      end

      it 'does not cache' do
        expect {
          resolver.resolve(:foo)
        }.to_not change(resolver, :singletons)
      end
    end
  end

  describe '.resolve_bean' do
    context 'bean is value bean' do
      let(:bean) { double('value', value: 1) }

      before do
        allow(resolver).to receive(:resolve_value_bean).and_return(instance)
      end

      it 'returns instance' do
        expect(resolver.send(:resolve_bean, bean)).to eq(instance)
      end

      it 'resolves bean as value bean' do
        expect(resolver).to receive(:resolve_value_bean).with(bean)

        resolver.send(:resolve_bean, bean)
      end
    end

    context 'bean is a class bean' do
      let(:bean) { double('class', value: nil, klass: 'Foo') }

      before do
        allow(resolver).to receive(:resolve_class_bean).and_return(instance)
      end

      it 'returns instance' do
        expect(resolver.send(:resolve_bean, bean)).to eq(instance)
      end

      it 'resolves bean as a class bean' do
        expect(resolver).to receive(:resolve_class_bean).with(bean)

        resolver.send(:resolve_bean, bean)
      end
    end
  end

  describe '.resolve_value_bean' do
    context 'value is a Proc' do
      let(:bean) { double('proc value', value: proc { 1 }) }

      it 'returns 1' do
        expect(resolver.send(:resolve_value_bean, bean)).to eq(1)
      end
    end

    context 'value is a scalar' do
      let(:bean) { double('proc value', value: 1) }

      it 'returns 1' do
        expect(resolver.send(:resolve_value_bean, bean)).to eq(1)
      end
    end
  end

  describe '.resolve_class_bean' do
    let(:hacked_string) { double('string', constantize: klass) }
    let(:bean) { double('class bean', class_name: hacked_string) }

    context 'constructor has no parameters' do
      let(:klass) { Class.new { def initialize; end } }

      it 'returns an instance of the given class' do
        expect(resolver.send(:resolve_class_bean, bean).is_a?(klass)).to be_truthy
      end
    end

    context 'constructor has parameters' do
      context 'constructor has parameters that are not of "key" type' do
        let(:klass) { Class.new { def initialize(a); end } }

        it 'raise error' do
          expect {
            resolver.send(:resolve_class_bean, bean)
          }.to raise_error(ArgumentError)
        end
      end

      context 'constructor has only "key" type parameters' do
        let(:klass) { Class.new { def initialize(a:); end } }
        let(:random_instance) { double('param instance') }
        let(:param_ref) { :foo }

        before do
          allow(resolver).to receive(:resolve_attribute).and_return(param_ref)
          allow(resolver).to receive(:bean).and_return(random_instance)
        end

        it 'resolves constructor attributes references' do
          expect(resolver).to receive(:resolve_attribute).with(bean, :a)

          resolver.send(:resolve_class_bean, bean)
        end

        it 'resolves constructor attributes' do
          expect(resolver).to receive(:bean).with(param_ref)

          resolver.send(:resolve_class_bean, bean)
        end

        it 'returns an instance of the given class with parameters' do
          expect(klass).to receive(:new).with(a: random_instance).and_call_original
          expect(resolver.send(:resolve_class_bean, bean).is_a?(klass)).to be_truthy
        end
      end
    end
  end

  describe '.resolve_attribute' do
    context 'bean has aliased attributes' do
      let(:attr) { double('attr', reference: :bar) }
      let(:bean) { double('bean', attributes: { foo: attr }) }

      it 'resolves a given attribute into its alias' do
        expect(resolver.send(:resolve_attribute, bean, :foo)).to eq(:bar)
      end
    end

    context 'bean has no aliased attribute' do
      let(:bean) { double('bean', attributes: {}) }

      it 'resolves a given attribute into itself' do
        expect(resolver.send(:resolve_attribute, bean, :foo)).to eq(:foo)
      end
    end
  end
end
