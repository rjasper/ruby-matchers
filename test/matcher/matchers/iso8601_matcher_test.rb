# frozen_string_literal: true

require 'test_helper'

describe Matcher::Iso8601Matcher do
  it 'match any ISO 8601 string' do
    matcher = Matcher::Iso8601Matcher.new

    assert_no_errors matcher.match('2024-07-04T14:09:39+02:00')
    assert_expected_errors matcher.match('foobar'), 'expected an ISO 8601 string but got "foobar"'
    assert_expected_errors matcher.match(1), 'expected a kind of String but got 1'

    negated = ~matcher

    assert_expected_errors negated.match('2024-07-04T14:09:39+02:00'),
      'did not expect an ISO 8601 string but got "2024-07-04T14:09:39+02:00"'
    assert_no_errors negated.match('foobar')
    assert_no_errors negated.match(1)
  end

  it 'match time from string' do
    matcher = Matcher::Iso8601Matcher.new('2024-07-04T14:09:39+02:00')

    assert_no_errors matcher.match('2024-07-04T14:09:39+02:00')
    assert_expected_errors matcher.match('2020-01-05T12:20:32+02:00'),
      'expected 2024-07-04 14:09:39 +0200 but got "2020-01-05T12:20:32+02:00"'

    negated = ~matcher

    assert_expected_errors negated.match('2024-07-04T14:09:39+02:00'),
      'did not expect "2024-07-04T14:09:39+02:00"'
    assert_no_errors negated.match('2020-01-05T12:20:32+02:00')
  end

  it 'match time' do
    time = Time.new(2024, 7, 4, 14, 9, 39, '+02:00')
    matcher = Matcher::Iso8601Matcher.new(time)

    assert_no_errors matcher.match('2024-07-04T14:09:39+02:00')
    assert_expected_errors matcher.match('2020-01-05T12:20:32+02:00'),
      'expected 2024-07-04 14:09:39 +0200 but got "2020-01-05T12:20:32+02:00"'
  end

  it '#to_s' do
    assert_equal 'iso8601', Matcher::Iso8601Matcher.new.to_s
    assert_equal 'iso8601("2024-07-04T14:09:39+04:00")',
      Matcher::Iso8601Matcher.new(Time.new(2024, 7, 4, 14, 9, 39, '+04:00')).to_s
    assert_equal 'iso8601("2024-07-04T14:09:39+04:00")',
      Matcher::Iso8601Matcher.new('2024-07-04T14:09:39+04:00').to_s
  end
end
