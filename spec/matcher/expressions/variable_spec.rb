# frozen_string_literal: true

require 'test_helper'

describe Matcher::Variable do
  it '#variables' do
    assert_equal [:foo], Matcher::Variable.new(:foo).variables
  end

  describe '#evaluate' do
    it 'return value' do
      foo = Matcher::Variable.new(:foo)

      assert_equal 'foo', foo.evaluate(foo: 'foo')
    end

    it 'raises error if value not given' do
      foo = Matcher::Variable.new(:foo)

      err = assert_raises StandardError do
        foo.evaluate(bar: 'bar')
      end

      assert_equal 'no value for :foo', err.message
    end
  end

  describe '#substitute' do
    it 'replaces its symbol' do
      foo = Matcher::Variable.new(:foo)

      assert_equal :bar, foo.substitute(foo: :bar).symbol
    end
  end

  describe '#to_s' do
    it 'stringifies its symbol' do
      assert_equal 'foo', Matcher::Variable.new(:foo).to_s
    end

    it 'substitutes its symbol' do
      var = Matcher::Variable.new(:hello)

      assert_equal 'hi', var.to_s(substitutions: { hello: 'hi' })
    end

    it 'applies default substitutions' do
      assert_equal '_', Matcher::Variable.new(:actual).to_s
    end
  end
end
