# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class ExpressionMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'evaluates expressions' do
      assert_not_predicate match(2) { value > 2 }, :valid?
      assert_predicate match(3) { value.odd? }, :valid?
      assert_predicate match(3) { value + value * 2 == 9 }, :valid?
      assert_predicate match('Hello World') { value.upcase.gsub(' ', '_') == 'HELLO_WORLD' }, :valid?
    end

    test 'generates error message' do
      assert_errors match('string') { value.is_a?(Numeric) },
        'expected value to be a kind of Numeric but got "string"'
      assert_errors match({ foo: {} }) { value[:foo][:bar].baz? },
        'expected value[:foo][:bar] to respond to baz? but got nil where value = {:foo=>{}}'
      assert_errors match(1.0) { (value + 1).is_a?(Integer) },
        'expected value + 1 to be a kind of Integer but got 2.0 for value = 1.0'
      assert_errors match(7) { value % 3 == 0 },
        'expected value % 3 to be 0 but got 1 for value = 7'
      assert_errors match(6) { value % 3 != 0 },
        'expected value % 3 to not be 0 for value = 6'
      assert_errors match(7) { value > 10 },
        'expected value to be > 10 but got 7'
      assert_errors match('Hi') { value.downcase =~ /hello/ },
        'expected value.downcase to match /hello/ but got "hi" for value = "Hi"'
      assert_errors match('FooBar') { value.downcase !~ /foo/ },
        'expected value.downcase to not match /foo/ but got "foobar" for value = "FooBar"'
      assert_errors match(7) { value.even? },
        'expected value to be even but got 7'
      assert_errors match(7) { (value + 1).odd? },
        'expected value + 1 to be odd but got 8 for value = 7'
    end

    test '#inspect' do
      matcher = Matcher.build { value * 3 > 9 }

      assert_equal 'value * 3 > 9', matcher.inspect
    end
  end
end
