# frozen_string_literal: true

require 'test_helper'

describe Matcher::Variable do
  describe '::cache' do
    it 'returns cached actual' do
      assert_kind_of Matcher::Variable, Matcher::Variable.cache(:actual)
      assert_same Matcher::Variable.actual, Matcher::Variable.cache(:actual)
    end

    it 'caches with build session' do
      Matcher.with_build_session do
        foo = Matcher::Variable.cache(:foo)

        assert_kind_of Matcher::Variable, foo
        assert_same foo, Matcher::Variable.cache(:foo)
      end
    end

    it 'falls back to new without build session' do
      assert_kind_of Matcher::Variable, Matcher::Variable.cache(:foo)
    end
  end

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

      actual = Matcher::Variable.with_substitutions(hello: 'hi') do
        var.to_s
      end

      assert_equal 'hi', actual
    end
  end
end
