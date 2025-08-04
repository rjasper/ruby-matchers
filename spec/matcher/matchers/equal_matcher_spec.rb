# frozen_string_literal: true

require 'test_helper'

describe Matcher::EqualMatcher do
  it 'is built by equal and from objects' do
    assert_kind_of(Matcher::EqualMatcher, Matcher.build { equal(String) })
    assert_kind_of(Matcher::EqualMatcher, Matcher.build { 1 })
  end

  it 'matches value' do
    matcher = Matcher.build { 42 }
    negated = ~matcher

    assert_no_errors matcher.match(42)
    assert_errors negated.match(42),
      msg(42).equal(42)

    assert_errors matcher.match(23),
      msg(23).not.equal(42)
    assert_no_errors negated.match(23)
  end

  it 'matches expression' do
    matcher = Matcher.build do
      let(foo: 3) ^ equal(vars[:foo] * 14)
    end

    negated = ~matcher

    assert_no_errors matcher.match(42)
    assert_errors negated.match(42),
      msg(42).equal(42)

    assert_errors matcher.match(23),
      msg(23).not.equal(42)
    assert_no_errors negated.match(23)
  end

  it '#to_s' do
    matcher = Matcher::EqualMatcher.new(1)

    assert_equal '1', matcher.to_s
    assert_equal 'neg(1)', matcher.~.to_s

    matcher = Matcher::EqualMatcher.new(1..10)

    assert_equal 'equal(1..10)', matcher.to_s
    assert_equal '~equal(1..10)', matcher.~.to_s
  end
end
