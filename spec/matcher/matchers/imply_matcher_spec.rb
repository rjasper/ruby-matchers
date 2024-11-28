# frozen_string_literal: true

require 'test_helper'

describe Matcher::ImplyMatcher do
  it 'is built by imply' do
    matcher = Matcher.build { imply(Integer, 1) }

    assert_kind_of Matcher::ImplyMatcher, matcher
  end

  it 'matches against implied matchers' do
    matcher = Matcher.build { imply(String, 'string') }
    negated = ~matcher

    assert_no_errors matcher.match('string')
    assert_errors negated.match('string'),
      msg('string').equal('string')

    assert_errors matcher.match('foo'),
      msg('foo').not.equal('string')
    assert_no_errors negated.match('foo')

    assert_no_errors matcher.match(1)
    assert_errors negated.match(1),
      msg(1).not.kind_of(String)
  end

  it '#to_s' do
    matcher = Matcher.build { imply(String, 'string') }

    assert_equal 'imply(String, "string")', matcher.to_s
    assert_equal '~imply(String, "string")', matcher.~.to_s
  end
end
