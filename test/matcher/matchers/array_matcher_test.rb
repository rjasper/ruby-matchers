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

    test 'match not array' do
      matcher = ~ArrayMatcher.new([v(1), v(2), v(3)])

      assert_errors matcher.match([1, 2, 3]) do
        _or do
          error(0, 'expected 1 to not be 1')
          error(1, 'expected 2 to not be 2')
          error(2, 'expected 3 to not be 3')
        end
      end

      assert_predicate matcher.match([1, 2, 4]), :valid?
      assert_predicate matcher.match(nil), :valid?
      assert_predicate matcher.match([]), :valid?
      assert_predicate matcher.match([1, 2, 3, 4]), :valid?
      assert_predicate matcher.match([4, 5, 6]), :valid?
    end

    test 'pass index' do
      expression = Call.build(:actual, :index) do |_, i|
        _ == i * 10
      end

      item_matcher = Matcher.of(expression)

      matcher = ArrayMatcher.new([item_matcher, item_matcher, item_matcher])

      assert_predicate matcher.match([0, 10, 20]), :valid?
      assert_errors matcher.match([0, 11, 20]),
        1 => 'expected _ to be i * 10 (10) but got 11 for i = 1'
    end

    test 'pass parent' do
      item_matcher = Matcher.build do
        parent[i - 1] < parent[i]
      end

      matcher = ArrayMatcher.new([Matcher.of(Integer), item_matcher, item_matcher])

      assert_predicate matcher.match([1, 3, 5]), :valid?
      assert_errors matcher.match([1, 5, 3]),
        2 => 'expected parent[i - 1] to be < parent[i] (3) but got 5 for parent = [1, 5, 3], i = 2'
    end

    test '#inspect' do
      matcher = ArrayMatcher.new([v(1), v(2), v(3)])

      assert_equal '[1, 2, 3]', matcher.inspect
      assert_equal 'neg([1, 2, 3])', (~matcher).inspect
    end
  end
end
