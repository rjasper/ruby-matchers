# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class ExpressionMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'evaluates expressions' do
      assert_not_predicate match(2) { _ > 2 }, :valid?
      assert_predicate match(3) { _.odd? }, :valid?
      assert_predicate match(3) { _ + _ * 2 == 9 }, :valid?
      assert_predicate match('Hello World') { _.upcase.gsub(' ', '_') == 'HELLO_WORLD' }, :valid?
    end

    test 'generates error message' do
      assert_errors match('string') { _.is_a?(Numeric) },
        'expected actual to be a kind of Numeric but got "string"'
      assert_errors match({ foo: {} }) { _[:foo][:bar].baz? },
        'expected actual[:foo][:bar] to respond to baz? but got nil where actual = {:foo=>{}}'
      assert_errors match(1.0) { (_ + 1).is_a?(Integer) },
        'expected actual + 1 to be a kind of Integer but got 2.0 for actual = 1.0'
      assert_errors match(7) { _ % 3 == 0 },
        'expected actual % 3 to be 0 but got 1 for actual = 7'
      assert_errors match(6) { _ % 3 != 0 },
        'expected actual % 3 to not be 0 for actual = 6'
      assert_errors match(7) { _ > 10 },
        'expected actual to be > 10 but got 7'
      assert_errors match('Hi') { _.downcase =~ /hello/ },
        'expected actual.downcase to match /hello/ but got "hi" for actual = "Hi"'
      assert_errors match('FooBar') { _.downcase !~ /foo/ },
        'expected actual.downcase to not match /foo/ but got "foobar" for actual = "FooBar"'
      assert_errors match(7) { _.even? },
        'expected actual to be even but got 7'
      assert_errors match(7) { (_ + 1).odd? },
        'expected actual + 1 to be odd but got 8 for actual = 7'
    end

    test '#inspect' do
      matcher = Matcher.build { _ * 3 > 9 }

      assert_equal 'actual * 3 > 9', matcher.inspect
    end
  end
end
