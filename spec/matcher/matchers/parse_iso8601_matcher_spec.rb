# frozen_string_literal: true

require 'test_helper'

describe Matcher::ParseIso8601Matcher do
  it 'is built by parse_iso8601' do
    time = Time.utc(2023)
    matcher = Matcher.build { parse_iso8601(_ < time) }

    assert_kind_of Matcher::ParseIso8601Matcher, matcher

    matcher = Matcher.build { parse_iso8601 ^ (_ < time) }

    assert_kind_of Matcher::ParseIso8601Matcher, matcher
  end

  it 'matches time from string' do
    year1990 = Time.utc(1990)
    year2000 = Time.utc(2000)
    year2024 = Time.utc(2024)

    matcher = Matcher.build { parse_iso8601(_ > year2000) }
    negated = ~matcher

    time_of = expression { expr(Time).iso8601(_) }

    assert matcher.match?('2024-01-01T00:00:00Z')
    assert_no_errors matcher.match('2024-01-01T00:00:00Z')
    refute negated.match?('2024-01-01T00:00:00Z')
    assert_errors negated.match('2024-01-01T00:00:00Z'),
      time_of => msg(year2024).greater_than(year2000)

    refute matcher.match?('foo')
    assert_errors matcher.match('foo'),
      msg('foo').not.valid_format(:iso8601)
    assert negated.match?('foo')
    assert_no_errors negated.match('foo')

    refute matcher.match?('1990-01-01T00:00:00Z')
    assert_errors matcher.match('1990-01-01T00:00:00Z'),
      time_of => msg(year1990).not.greater_than(year2000)
    assert negated.match?('1990-01-01T00:00:00Z')
    assert_no_errors negated.match('1990-01-01T00:00:00Z')
  end

  it 'matches iso8601 format' do
    matcher = Matcher.build { iso8601_format }
    negated = ~matcher

    assert matcher.match?('2024-01-01T00:00:00Z')
    assert_no_errors matcher.match('2024-01-01T00:00:00Z')
    refute negated.match?('2024-01-01T00:00:00Z')
    assert_errors negated.match('2024-01-01T00:00:00Z'),
      msg('2024-01-01T00:00:00Z').valid_format(:iso8601)

    refute matcher.match?('foo')
    assert_errors matcher.match('foo'),
      msg('foo').not.valid_format(:iso8601)
    assert negated.match?('foo')
    assert_no_errors negated.match('foo')
  end

  it '#to_s' do
    time = Time.utc(2023)

    assert_equal 'parse_iso8601(actual < 2023-01-01 00:00:00 UTC)',
      Matcher.build { parse_iso8601(_ < time) }.to_s
    assert_equal '~parse_iso8601(actual < 2023-01-01 00:00:00 UTC)',
      Matcher.build { ~parse_iso8601(_ < time) }.to_s

    assert_equal 'iso8601_format',
      Matcher.build { iso8601_format }.to_s
    assert_equal '~iso8601_format',
      Matcher.build { ~iso8601_format }.to_s
  end
end
