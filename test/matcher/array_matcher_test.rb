# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class ArrayMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match array' do
      matcher = ArrayMatcher.new([v(1), v(2), v(3)])

      assert_predicate matcher.match([1, 2, 3]), :valid?
      assert_errors matcher.match(nil),
        'expected an Array but got nil'
      assert_errors matcher.match([]),
        'expected length of 3 but got 0'
      assert_errors matcher.match([1, 2, 3, 4]),
        'expected length of 3 but got 4'
      assert_errors matcher.match([4, 5, 6]),
        0 => 'expected 1 but got 4',
        1 => 'expected 2 but got 5',
        2 => 'expected 3 but got 6'
    end

    test '#inspect' do
      matcher = ArrayMatcher.new([v(1), v(2), v(3)])

      assert_equal '[1, 2, 3]', matcher.inspect
    end
  end
end
