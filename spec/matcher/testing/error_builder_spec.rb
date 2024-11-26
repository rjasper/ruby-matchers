# frozen_string_literal: true

require 'test_helper'

describe Matcher::ErrorBuilder do
  include Matcher::ErrorTesting

  let(:klass) { Matcher::ErrorBuilder }

  describe '#error' do
    it 'builds an ElementError' do
      errors = klass.build_errors do
        error 'foo'
      end

      assert_equal [element('foo')], errors
    end

    it 'builds a nested element if key is given' do
      errors = klass.build_errors do
        error :foo, 'bar'
      end

      assert_equal [nested(expression { _[:foo] }, element('bar'))], errors
    end

    it 'builds a deeply nested element path is given' do
      errors = klass.build_errors do
        error %i[foo bar], 'baz'
      end

      baz = element('baz')
      bar = nested(expression { _[:bar] }, baz)
      foo = nested(expression { _[:foo] }, bar)

      assert_equal [foo], errors
    end
  end

  describe '#_or' do
    it 'builds OrError from multiple errors' do
      errors = klass.build_errors do
        _or do
          error 'foo'
          error 'bar'
        end
      end

      assert_equal [_or(element('foo'), element('bar'))], errors
    end

    it 'builds nested OrError if path is given' do
      errors = klass.build_errors do
        _or :foo, :bar do
          error 'baz'
          error 'qux'
        end
      end

      baz_or_quux = _or(element('baz'), element('qux'))
      bar = nested(expression { _[:bar] }, baz_or_quux)
      foo = nested(expression { _[:foo] }, bar)

      assert_equal [foo], errors
    end
  end

  describe '#_and' do
    it 'builds AndError from multiple errors' do
      errors = klass.build_errors do
        _and do
          error 'foo'
          error 'bar'
        end
      end

      assert_equal [_and(element('foo'), element('bar'))], errors
    end

    it 'builds nested AndError if path is given' do
      errors = klass.build_errors do
        _and :foo, :bar do
          error 'baz'
          error 'qux'
        end
      end

      baz_or_quux = _and(element('baz'), element('qux'))
      bar = nested(expression { _[:bar] }, baz_or_quux)
      foo = nested(expression { _[:foo] }, bar)

      assert_equal [foo], errors
    end
  end

  describe '::build' do
    it 'returns EmptyError if no build was built' do
      assert_equal(empty, klass.build {})
    end

    it 'returns first error if only one was built' do
      error = klass.build do
        error 'foo'
      end

      assert_equal element('foo'), error
    end

    it 'combines multiple error into AndError' do
      error = klass.build do
        error 'foo'
        error 'bar'
      end

      assert_kind_of Matcher::AndError, error
      assert_equal [element('foo'), element('bar')], error.children
    end
  end
end
