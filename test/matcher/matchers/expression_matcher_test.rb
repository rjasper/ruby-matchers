# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::EqualMatcher do
  it 'evaluates expressions' do
    refute_predicate match(2) { _ > 2 }, :valid?
    assert_predicate match(3) { _.odd? }, :valid?
    assert_predicate match(3) { _ + _ * 2 == 9 }, :valid?
    assert_predicate match('Hello World') { _.upcase.gsub(' ', '_') == 'HELLO_WORLD' }, :valid?

    assert_predicate not_match(4) { _.odd? }, :valid?
    refute_predicate not_match(5) { _.odd? }, :valid?
  end

  it 'generates error message' do
    assert_errors match('string') { _.is_a?(Numeric) },
      'expected _ to be a kind of Numeric but got "string"'
    assert_errors match({ foo: {} }) { _[:foo][:bar].baz? },
      'expected _[:foo][:bar] to respond to baz? but got nil where _ = {:foo=>{}}'
    assert_errors match(1.0) { (_ + 1).is_a?(Integer) },
      'expected _ + 1 to be a kind of Integer but got 2.0 for _ = 1.0'
    assert_errors match(1) { _.instance_of?(Float) },
      'expected _ to be an instance of Float but got 1'
    assert_errors match(7) { _ % 3 == 0 },
      'expected _ % 3 to be 0 but got 1 for _ = 7'
    assert_errors match(6) { _ % 3 != 0 },
      'expected _ % 3 to not be 0 for _ = 6'
    assert_errors match(7) { _ > 10 },
      'expected _ to be > 10 but got 7'
    assert_errors match('Hi') { _.downcase =~ /hello/ },
      'expected _.downcase to match /hello/ but got "hi" for _ = "Hi"'
    assert_errors match('FooBar') { _.downcase !~ /foo/ },
      'expected _.downcase to not match /foo/ but got "foobar" for _ = "FooBar"'
    assert_errors match(7) { _.even? },
      'expected _ to be even but got 7'
    assert_errors match(7) { (_ + 1).odd? },
      'expected _ + 1 to be odd but got 8 for _ = 7'

    assert_errors not_match(0) { _ == 0 },
      'expected _ to not be 0'
    assert_errors not_match(1) { _ != 0 },
      'expected _ to be 0 but got 1'
    assert_errors not_match(-1) { _ < 0 },
      'expected _ to be >= 0 but got -1'
    assert_errors not_match(1) { _ > 0 },
      'expected _ to be <= 0 but got 1'
    assert_errors not_match(0) { _ <= 0 },
      'expected _ to be > 0 but got 0'
    assert_errors not_match(0) { _ >= 0 },
      'expected _ to be < 0 but got 0'
    assert_errors not_match(1) { _.is_a?(Numeric) },
      'expected _ to not be a kind of Numeric but got 1'
    assert_errors not_match(1) { (_ + 1).is_a?(Integer) },
      'expected _ + 1 to not be a kind of Integer but got 2 for _ = 1'
    assert_errors not_match(6) { _ % 3 == 0 },
      'expected _ % 3 to not be 0 for _ = 6'
    assert_errors not_match(7) { _ % 3 != 0 },
      'expected _ % 3 to be 0 but got 1 for _ = 7'
    assert_errors not_match(11) { _ > 10 },
      'expected _ to be <= 10 but got 11'
    assert_errors not_match('Hello') { _.downcase =~ /hello/ },
      'expected _.downcase to not match /hello/ but got "hello" for _ = "Hello"'
    assert_errors not_match('Bar') { _.downcase !~ /foo/ },
      'expected _.downcase to match /foo/ but got "bar" for _ = "Bar"'
    assert_errors not_match(8) { _.even? },
      'expected _ to not be even but got 8'
    assert_errors not_match(6) { (_ + 1).odd? },
      'expected _ + 1 to not be odd but got 7 for _ = 6'
  end

  it '#to_s' do
    matcher = Matcher.build { _ * 3 > 9 }

    assert_equal '_ * 3 > 9', matcher.to_s
    assert_equal 'neg(_ * 3 > 9)', (~matcher).to_s
  end
end
