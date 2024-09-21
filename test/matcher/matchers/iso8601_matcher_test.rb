# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class Iso8601MatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match any ISO 8601 string' do
      matcher = Iso8601Matcher.new

      assert_predicate matcher.match('2024-07-04T14:09:39+02:00'), :valid?
      assert_errors matcher.match('foobar'), 'expected an ISO 8601 string but got "foobar"'
      assert_errors matcher.match(1), 'expected a String but got 1'

      negated = ~matcher

      assert_errors negated.match('2024-07-04T14:09:39+02:00'),
        'did not expect an ISO 8601 string but got "2024-07-04T14:09:39+02:00"'
      assert_predicate negated.match('foobar'), :valid?
      assert_predicate negated.match(1), :valid?
    end

    test 'match time from string' do
      matcher = Iso8601Matcher.new('2024-07-04T14:09:39+02:00')

      assert_predicate matcher.match('2024-07-04T14:09:39+02:00'), :valid?
      assert_errors matcher.match('2020-01-05T12:20:32+02:00'),
        'expected 2024-07-04 14:09:39 +0200 but got 2020-01-05 12:20:32 +0200'

      negated = ~matcher

      assert_errors negated.match('2024-07-04T14:09:39+02:00'),
        'did not expect an ISO 8601 string for 2024-07-04 14:09:39 +0200 but got "2024-07-04T14:09:39+02:00"'
      assert_predicate negated.match('2020-01-05T12:20:32+02:00'), :valid?
    end

    test 'match time' do
      time = Time.new(2024, 7, 4, 14, 9, 39, '+02:00')
      matcher = Iso8601Matcher.new(time)

      assert_predicate matcher.match('2024-07-04T14:09:39+02:00'), :valid?
      assert_errors matcher.match('2020-01-05T12:20:32+02:00'),
        'expected 2024-07-04 14:09:39 +0200 but got 2020-01-05 12:20:32 +0200'
    end

    test '#inspect' do
      assert_equal 'iso8601', Iso8601Matcher.new.inspect
      assert_equal 'iso8601("2024-07-04T14:09:39+04:00")',
        Iso8601Matcher.new(Time.new(2024, 7, 4, 14, 9, 39, '+04:00')).inspect
      assert_equal 'iso8601("2024-07-04T14:09:39+04:00")',
        Iso8601Matcher.new('2024-07-04T14:09:39+04:00').inspect
    end
  end
end
