# frozen_string_literal: true

require 'test_helper'

describe Matcher::AlwaysMatcher do
  it 'is built by always' do
    matcher = Matcher.build { always }

    assert_kind_of Matcher::AlwaysMatcher, matcher
  end

  it 'matches always' do
    matcher = Matcher.build { always }
    negated = ~matcher

    assert_no_errors matcher.match(nil)
    assert_errors negated.match(nil), msg(nil).exist

    assert_no_errors matcher.match(true)
    assert_errors negated.match(true), msg(true).exist

    assert_no_errors matcher.match(1)
    assert_errors negated.match(1), msg(1).exist

    assert_no_errors matcher.match({})
    assert_errors negated.match({}), msg({}).exist

    assert_no_errors matcher.match([])
    assert_errors negated.match([]), msg([]).exist
  end

  it '#~' do
    matcher = Matcher.build { always }

    assert_kind_of Matcher::NeverMatcher, ~matcher
  end

  it '#&' do
    matcher = Matcher.build { always & equal(1) }

    assert_kind_of Matcher::EqualMatcher, matcher
  end

  it '#|' do
    matcher = Matcher.build { always | equal(1) }

    assert_kind_of Matcher::EqualMatcher, matcher
  end

  it '#to_s' do
    matcher = Matcher.build { always }

    assert_equal 'always', matcher.to_s
  end
end
