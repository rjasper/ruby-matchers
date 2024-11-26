# frozen_string_literal: true

require 'test_helper'

describe Matcher::Testing::ErrorBuilder do
  include Matcher::ErrorsTesting

  let(:klass) { Matcher::Testing::ErrorBuilder }

  describe '#error' do
    it 'builds an ElementError' do
      nodes = klass.build_nodes do
        error 'foo'
      end

      assert_equal [element('foo')], nodes
    end

    it 'builds a nested element if key is given' do
      nodes = klass.build_nodes do
        error :foo, 'bar'
      end

      assert_equal [nested(expression { _[:foo] }, element('bar'))], nodes
    end

    it 'builds a deeply nested element path is given' do
      nodes = klass.build_nodes do
        error %i[foo bar], 'baz'
      end

      baz = element('baz')
      bar = nested(expression { _[:bar] }, baz)
      foo = nested(expression { _[:foo] }, bar)

      assert_equal [foo], nodes
    end
  end

  describe '#_or' do
    it 'builds OrError from multiple nodes' do
      nodes = klass.build_nodes do
        _or do
          error 'foo'
          error 'bar'
        end
      end

      assert_equal [_or(element('foo'), element('bar'))], nodes
    end

    it 'builds nested OrError if path is given' do
      nodes = klass.build_nodes do
        _or :foo, :bar do
          error 'baz'
          error 'qux'
        end
      end

      baz_or_quux = _or(element('baz'), element('qux'))
      bar = nested(expression { _[:bar] }, baz_or_quux)
      foo = nested(expression { _[:foo] }, bar)

      assert_equal [foo], nodes
    end
  end

  describe '#_and' do
    it 'builds AndError from multiple nodes' do
      nodes = klass.build_nodes do
        _and do
          error 'foo'
          error 'bar'
        end
      end

      assert_equal [_and(element('foo'), element('bar'))], nodes
    end

    it 'builds nested AndError if path is given' do
      nodes = klass.build_nodes do
        _and :foo, :bar do
          error 'baz'
          error 'qux'
        end
      end

      baz_or_quux = _and(element('baz'), element('qux'))
      bar = nested(expression { _[:bar] }, baz_or_quux)
      foo = nested(expression { _[:foo] }, bar)

      assert_equal [foo], nodes
    end
  end

  describe '::build' do
    it 'returns EmptyError if no build was built' do
      assert_equal(empty, klass.build {})
    end

    it 'returns first node if only one was built' do
      node = klass.build do
        error 'foo'
      end

      assert_equal element('foo'), node
    end

    it 'combines multiple node into AndError' do
      node = klass.build do
        error 'foo'
        error 'bar'
      end

      assert_kind_of Matcher::AndError, node
      assert_equal [element('foo'), element('bar')], node.nodes
    end
  end
end
