# frozen_string_literal: true

require 'test_helper'

describe Matcher::ParseTimeMatcher do

  it 'is built by parse_time' do
    time = Time.new(2023)
    matcher = Matcher.build { parse_time(_ < time) }

    assert_kind_of Matcher::ParseTimeMatcher, matcher

    matcher = Matcher.build { parse_time ^ (_ < time) }

    assert_kind_of Matcher::ParseTimeMatcher, matcher
  end

  it 'matches time from string' do
    year1990 = Time.new(1990)
    year2000 = Time.new(2000)
    year2024 = Time.new(2024)

    matcher = Matcher.build { parse_time(_ > year2000) }
    negated = ~matcher

    time_of = expression { expr(Time).parse(_) }

    assert_no_errors matcher.match('2024-01-01')
    assert_errors negated.match('2024-01-01'),
      time_of => msg(year2024).greater_than(year2000)

    assert_errors matcher.match('foo'),
      msg('foo').not.valid_format(:time)
    assert_no_errors negated.match('foo')

    assert_errors matcher.match('1990-01-01'),
      time_of => msg(year1990).not.greater_than(year2000)
    assert_no_errors negated.match('1990-01-01')
  end

  it '#to_s' do
    time = Time.new(2023)

    assert_equal 'parse_time(_ < 2023-01-01 00:00:00 +0100)',
      Matcher.build { parse_time(_ < time) }.to_s
    assert_equal '~parse_time(_ < 2023-01-01 00:00:00 +0100)',
      Matcher.build { ~parse_time(_ < time) }.to_s
  end
end
