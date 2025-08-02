# frozen_string_literal: true

require 'test_helper'

describe Matcher::NeverMatcher do
  it 'is built by never' do
    matcher = Matcher.build { never }

    assert_kind_of Matcher::NeverMatcher, matcher
  end

  it 'matchers never' do
    matcher = Matcher.build { never }
    negated = ~matcher

    assert_errors matcher.match(nil), msg(nil).exist
    assert_no_errors negated.match(nil)

    assert_errors matcher.match(true), msg(true).exist
    assert_no_errors negated.match(true)

    assert_errors matcher.match(1), msg(1).exist
    assert_no_errors negated.match(1)

    assert_errors matcher.match({}), msg({}).exist
    assert_no_errors negated.match({})

    assert_errors matcher.match([]), msg([]).exist
    assert_no_errors negated.match([])
  end

  it '#~' do
    matcher = Matcher.build { never }

    assert_kind_of Matcher::AlwaysMatcher, ~matcher
  end

  it '#&' do
    matcher = Matcher.build { never & equal(1) }

    assert_kind_of Matcher::NeverMatcher, matcher
  end

  it '#|' do
    matcher = Matcher.build { never | equal(1) }

    assert_kind_of Matcher::EqualMatcher, matcher
  end

  it '#to_s' do
    matcher = Matcher.build { never }

    assert_equal 'never', matcher.to_s
  end
end
