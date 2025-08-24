# frozen_string_literal: true

require 'test_helper'

describe Matcher::KindOfMatcher do
  it 'is built from Module' do
    assert_kind_of(Matcher::KindOfMatcher, Matcher.build { String })
  end

  it 'matches Module' do
    matcher = Matcher.build { String }
    negated = ~matcher

    assert_no_errors matcher.match('asdf')
    assert_errors negated.match('asdf'),
      msg('asdf').kind_of(String)

    assert_errors matcher.match(1),
      msg(1).not.kind_of(String)
    assert_no_errors negated.match(1)
  end

  it '#to_s' do
    matcher = Matcher::KindOfMatcher.new(Integer)

    assert_equal 'Integer', matcher.to_s
    assert_equal 'neg(Integer)', matcher.~.to_s
  end
end
