# frozen_string_literal: true

require 'test_helper'

describe Matcher::OptionalMatcher do
  it 'is built by optional' do
    assert_kind_of(
      Matcher::OptionalMatcher,
      Matcher.build { optional(Integer) },
    )

    assert_kind_of(
      Matcher::OptionalMatcher,
      Matcher.build { ~optional(Integer) },
    )

    assert_kind_of(
      Matcher::OptionalMatcher,
      Matcher.build { optional ^ Integer },
    )

    assert_kind_of(
      Matcher::OptionalMatcher,
      Matcher.build { ~optional ^ Integer },
    )
  end

  it 'matches nil or matcher' do
    matcher = Matcher.build { optional(Integer) }
    negated = ~matcher

    assert_no_errors matcher.match(nil)
    assert_errors negated.match(nil),
      msg(nil).equal(nil)

    assert_no_errors matcher.match(1)
    assert_errors negated.match(1),
      msg(1).kind_of(Integer)

    assert_errors matcher.match('foo'),
      msg('foo').not.kind_of(Integer)
    assert_no_errors negated.match('foo')
  end

  it '#to_s' do
    assert_equal 'optional(Integer)', Matcher.build { optional(Integer) }.to_s
    assert_equal '~optional(Integer)', Matcher.build { ~optional(Integer) }.to_s
  end
end
