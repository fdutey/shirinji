# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Shirinji::Scope do
  let(:parent) { double(scope: nil, bean: nil) }
  let(:mod) { nil }
  let(:prefix) { nil }
  let(:suffix) { nil }
  let(:ks) { nil }
  let(:ak) { false }
  let(:ap) { nil }
  let(:construct) { nil }

  let(:scope) do
    described_class.new(
      parent,
      module: mod,
      prefix: prefix,
      suffix: suffix,
      klass_suffix: ks,
      auto_klass: ak,
      auto_prefix: ap,
      construct: construct
    )
  end

  describe '.bean' do
    context 'with prefix' do
      let(:prefix) { 'pre' }

      it 'prepends prefix in front of bean name' do
        expect(parent).to receive(:bean).with('pre_foo', klass: 'A')

        scope.bean('foo', klass: 'A')
      end
    end

    context 'with suffix' do
      let(:suffix) { 'suf' }

      it 'appends suffix at the end of bean name' do
        expect(parent).to receive(:bean).with('foo_suf', klass: 'A')

        scope.bean('foo', klass: 'A')
      end
    end

    context 'with class suffix' do
      let(:ks) { 'Service' }

      it 'appends klass suffix at the end of class name' do
        expect(parent).to receive(:bean).with('foo', klass: 'SignupService')

        scope.bean('foo', klass: 'Signup')
      end
    end

    context 'with module' do
      let(:mod) { 'Services' }

      it 'prepends module to klass name' do
        expect(parent).to receive(:bean).with('foo', klass: 'Services::Signup')

        scope.bean('foo', klass: 'Signup')
      end
    end

    context 'with auto klass' do
      let(:ak) { true }

      it 'generates klass name' do
        expect(parent).to receive(:bean).with('foo_bar', klass: 'FooBar')

        scope.bean('foo_bar')
      end
    end

    context 'with construct' do
      let(:construct) { false }

      it 'sets bean to construct false' do
        expect(parent).to receive(:bean).with('foo', construct: false)

        scope.bean('foo')
      end
    end

    context 'with auto prefix' do
      let(:ap) { true }
      let(:mod) { 'UserProfile' }

      it 'sets prefix' do
        expect(parent).to receive(:bean).with('user_profile_foo', {})

        scope.bean('foo')
      end
    end
  end

  describe '.scope' do
    it 'creates a new scope with current scope as parent' do
      res = scope.scope(prefix: 'a')

      expect(res).to be_a(Shirinji::Scope)
      expect(res.parent).to eq(scope)
    end
  end
end
