# frozen_string_literal: true

require 'test_helper'

describe Matcher::Iso8601Matcher do
  it 'is built by iso8601' do
    matcher = Matcher.build { iso8601 }

    assert_kind_of Matcher::Iso8601Matcher, matcher
  end

  it 'expects a String' do
    matcher = Matcher.build { iso8601 }

    assert_expected_errors matcher.match(1), 'expected a kind of String but got 1'
    assert_no_errors matcher.~.match(1)
  end

  it 'matches any ISO 8601 string' do
    matcher = Matcher.build { iso8601 }
    negated = ~matcher

    assert_no_errors matcher.match('2024-07-04T14:09:39+02:00')
    assert_expected_errors negated.match('2024-07-04T14:09:39+02:00'),
      'did not expect an ISO 8601 string but got "2024-07-04T14:09:39+02:00"'

    assert_expected_errors matcher.match('foobar'), 'expected an ISO 8601 string but got "foobar"'
    assert_no_errors negated.match('foobar')
  end

  it 'matches time from String' do
    matcher = Matcher.build { iso8601('2024-07-04T14:09:39+02:00') }
    negated = ~matcher

    assert_no_errors matcher.match('2024-07-04T14:09:39+02:00')
    assert_expected_errors negated.match('2024-07-04T14:09:39+02:00'),
      'did not expect "2024-07-04T14:09:39+02:00"'

    assert_expected_errors matcher.match('2020-01-05T12:20:32+02:00'),
      'expected 2024-07-04 14:09:39 +0200 but got "2020-01-05T12:20:32+02:00"'
    assert_no_errors negated.match('2020-01-05T12:20:32+02:00')
  end

  it 'matches from Time' do
    time = Time.new(2024, 7, 4, 14, 9, 39, '+02:00')
    matcher = Matcher.build { iso8601(time) }

    assert_no_errors matcher.match('2024-07-04T14:09:39+02:00')
    assert_expected_errors matcher.match('2020-01-05T12:20:32+02:00'),
      'expected 2024-07-04 14:09:39 +0200 but got "2020-01-05T12:20:32+02:00"'
  end

  it '#to_s: format' do
    matcher = Matcher.build { iso8601 }

    assert_equal 'iso8601', matcher.to_s
    assert_equal '~iso8601', matcher.~.to_s
  end

  it '#to_s: from String' do
    matcher = Matcher.build { iso8601('2024-07-04T14:09:39+04:00') }

    assert_equal 'iso8601("2024-07-04T14:09:39+04:00")', matcher.to_s
  end

  it '#to_s: from Time' do
    time = Time.new(2024, 7, 4, 14, 9, 39, '+04:00')
    matcher = Matcher.build { iso8601(time) }

    assert_equal 'iso8601("2024-07-04T14:09:39+04:00")', matcher.to_s
  end
end
