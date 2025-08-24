# frozen_string_literal: true

require 'test_helper'

describe Matcher::RegexpMatcher do
  it 'is built from Regexp' do
    assert_kind_of(Matcher::RegexpMatcher, Matcher.build { /f/ })
  end

  it 'matches Regexp' do
    matcher = Matcher.build { /f/ }
    negated = ~matcher

    assert_no_errors matcher.match('foo')
    assert_errors negated.match('foo'),
      msg('foo').matching(/f/)

    assert_errors matcher.match('bar'),
      msg('bar').not.matching(/f/)
    assert_no_errors negated.match('bar')
  end


  it '#to_s' do
    matcher = Matcher::RegexpMatcher.new(/asdf/)

    assert_equal '/asdf/', matcher.to_s
    assert_equal 'neg(/asdf/)', matcher.~.to_s
  end
end
