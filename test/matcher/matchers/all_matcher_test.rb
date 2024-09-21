# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class AllMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match all' do
      divisible_by_three = BlockMatcher.new(-> { _1 % 3 == 0 }, 'a number divisible by 3')
      even = BlockMatcher.new(-> { _1.even? }, 'an even number')
      matcher = AllMatcher.new([divisible_by_three, even])

      assert_predicate matcher.match(6), :valid?
      assert_not_predicate matcher.match(9), :valid?
      assert_not_predicate matcher.match(4), :valid?

      assert_errors matcher.match(5),
        'expected a number divisible by 3 but got 5',
        'expected an even number but got 5'
    end

    test '#&' do
      matcher = AllMatcher.new([v(1), v(2)]) & v(3)

      assert_equal 'all(1, 2, 3)', matcher.inspect
    end

    test '#inspect' do
      matcher = AllMatcher.new([v(1), v(2)])

      assert_equal 'all(1, 2)', matcher.inspect
      assert_equal 'any(neg(1), neg(2))', (~matcher).inspect
    end
  end
end
