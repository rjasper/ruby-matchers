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
  end
end
