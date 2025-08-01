# frozen_string_literal: true

require 'test_helper'

describe Matcher::ParseFloatMatcher do
  it 'is built by parse_float' do
    matcher = Matcher.build { parse_float(_.positive?) }

    assert_kind_of Matcher::ParseFloatMatcher, matcher

    matcher = Matcher.build { parse_float ^ _.positive? }

    assert_kind_of Matcher::ParseFloatMatcher, matcher
  end

  it 'matches float from string' do
    matcher = Matcher.build { parse_float(_.positive?) }
    negated = ~matcher

    float_of = expression { kernel::Float(_) }

    assert_no_errors matcher.match('2.5')
    assert_errors negated.match('2.5'),
      float_of => msg(2.5).predicate(:positive?)

    assert_errors matcher.match('foo'),
      msg('foo').not.valid_format(:float)
    assert_no_errors negated.match('foo')

    assert_errors matcher.match('-1.5'),
      float_of => msg(-1.5).not.predicate(:positive?)
    assert_no_errors negated.match('-1.5')
  end

  it '#to_s' do
    assert_equal 'parse_float(_.positive?)',
      Matcher.build { parse_float(_.positive?) }.to_s
  end
end
