# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::CaseEqualityMatcher do
  it '#matches case equality' do
    examine = -> { Matcher::CaseEqualityMatcher.new(_1).match(_2).valid? }

    assert examine.call(String, 'asdf')
    refute examine.call(String, 1)
    assert examine.call(1..3, 2)
    refute examine.call(1..3, 4)
    assert examine.call(/f/, 'foo')
    refute examine.call(/f/, 'bar')
    assert examine.call(Set[1, 2], 1)
    refute examine.call(Set[1, 2], 3)
  end

  it 'generates error messages' do
    assert_errors match('hi') { Integer },
      'expected "hi" to be kind of Integer'
    assert_errors match('foo') { /bar/ },
      'expected "foo" to match /bar/'
    assert_errors Matcher::CaseEqualityMatcher.new(Set[2, 3]).match(1),
      'expected 1 to be member of {2, 3}'
    assert_errors match(1) { 2..3 },
      'expected 1 to be within 2..3'
  end

  it '#to_s' do
    matcher = Matcher::CaseEqualityMatcher.new(Integer)

    assert_equal 'Integer', matcher.to_s
    assert_equal 'neg(Integer)', (~matcher).to_s
  end
end
