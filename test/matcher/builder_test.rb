# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class BuilderTest < ActiveSupport::TestCase
    include Testing

    test '#satisfy' do
      matcher = Matcher.build do
        satisfy('square root is bigger than 10') do |actual|
          Math.sqrt(actual) > 10
        end
      end

      assert_predicate matcher.match(1000), :valid?
      assert_not_predicate matcher.match(10), :valid?
    end

    test '#all_entries' do
      matcher = Matcher.build do
        all_entries({ a: { a1: 'a1' } })
      end

      assert_errors matcher.match({ a: { a1: 'a1', a2: 'a2' }, b: 'b' }),
        a: { a2: 'expected entry for :a2 to not be present' },
        b: 'expected entry for :b to not be present'
    end

    test '#partial_entries' do
      matcher = Matcher.build do
        partial_entries({ a: { a1: 'a1' } })
      end

      assert_predicate matcher.match({ a: { a1: 'a1', a2: 'a2' }, b: 'b' }), :valid?
    end

    test '#all' do
      matcher = Matcher.build do
        all(_.odd?, _ % 3 == 0)
      end

      assert_predicate matcher.match(3), :valid?
      assert_predicate matcher.match(9), :valid?
      assert_errors matcher.match(6), 'expected actual to be odd but got 6'
      assert_errors matcher.match(7), 'expected actual % 3 to be 0 but got 1 for actual = 7'
    end

    test '#any' do
      matcher = Matcher.build do
        any(_.even?, _ % 5 == 0, 37)
      end

      assert_predicate matcher.match(4), :valid?
      assert_predicate matcher.match(15), :valid?
      assert_predicate matcher.match(37), :valid?
      assert_errors matcher.match(17),
        'expected actual to be even but got 17',
        'expected actual % 5 to be 0 but got 2 for actual = 17',
        'expected 37 but got 17'
    end

    test 'value' do
      matcher = Matcher.build do
        42
      end

      assert_predicate matcher.match(42), :valid?
      assert_not_predicate matcher.match(23), :valid?
    end

    test 'block' do
      matcher = Matcher.build do
        -> { _1 > 0 }
      end

      assert_predicate matcher.match(10), :valid?
      assert_not_predicate matcher.match(-1), :valid?
    end

    test 'array' do
      matcher = Matcher.build do
        [1, 2, 3]
      end

      assert_predicate matcher.match([1, 2, 3]), :valid?
      assert_not_predicate matcher.match([4]), :valid?
    end

    test 'hash' do
      matcher = Matcher.build do
        { a: 1 }
      end

      assert_predicate matcher.match({ a: 1 }), :valid?
      assert_not_predicate matcher.match({ a: 2 }), :valid?
      assert_not_predicate matcher.match({ a: 1, b: 2 }), :valid?
    end
  end
end
