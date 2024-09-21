# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class SetMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match array' do
      matcher = SetMatcher.new([v(1), v(2), v(3)])

      assert_predicate matcher.match([3, 1, 2]), :valid?
      assert_errors matcher.match(nil),
        'expected an Array but got nil'
      assert_errors matcher.match([]),
        'expected length of 3 but got 0',
        'expected array to include 1',
        'expected array to include 2',
        'expected array to include 3'
      assert_errors matcher.match([1, 2, 3, 4]),
        'expected length of 3 but got 4'
      assert_errors matcher.match([1, 2, 4]),
        'expected array to include 3',
        2 => 'unexpected item 4'

      negated = ~matcher

      assert_errors negated.match([3, 1, 2]),
        'expected array to not be an equal set to [1, 2, 3] but got [3, 1, 2]'

      assert_predicate negated.match(nil), :valid?
      assert_predicate negated.match([]), :valid?
      assert_predicate negated.match([1, 2, 3, 4]), :valid?
      assert_predicate negated.match([1, 2, 4]), :valid?
    end

    test 'pass parent' do
      matcher = Matcher.build do
        set([_ == parent])
      end

      self_array = []
      self_array << self_array

      assert_predicate matcher.match(self_array), :valid?

      assert_errors matcher.match([1]),
        'expected array to include _ == parent',
        0 => 'unexpected item 1'
    end

    test '#inspect' do
      assert_equal 'set([1, 2, 3])', SetMatcher.new([v(1), v(2), v(3)]).inspect
    end
  end
end
