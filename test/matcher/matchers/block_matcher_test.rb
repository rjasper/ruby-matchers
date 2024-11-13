# frozen_string_literal: true

require 'test_helper'

describe Matcher::BlockMatcher do
  it 'validates blocks' do
    matcher = Matcher::BlockMatcher.new(-> { _1 > 2 }, nil)

    assert_no_errors matcher.match(4)
    refute_predicate matcher.match(0), :valid?
  end

  it 'generates message' do
    matcher = Matcher::BlockMatcher.new(-> { _1 == 42 }, 'an answer to everything')

    assert_errors matcher.match(3),
      msg_not(:described_by, 3, 'an answer to everything')
    assert_errors (~matcher).match(42),
      msg(:described_by, 42, 'an answer to everything')

    assert_expected_errors matcher.match(3),
      'expected an answer to everything but got 3'
    assert_expected_errors (~matcher).match(42),
      'did not expect an answer to everything but got 42'

    matcher = Matcher::BlockMatcher.new(-> { _1 == 'foo' })
    lineno = __LINE__ - 1

    assert_expected_errors matcher.match('bar'),
      "expected to satisfy condition block_matcher_test.rb:#{lineno} but got \"bar\""
    assert_expected_errors (~matcher).match('foo'),
      "did not expect to satisfy condition block_matcher_test.rb:#{lineno} but got \"foo\""
  end

  it '#to_s: with message' do
    matcher = Matcher::BlockMatcher.new(-> { _1 % 3 == 0 }, 'a number divisible by three')

    assert_equal 'a number divisible by three', matcher.to_s
    assert_equal 'neg(a number divisible by three)', (~matcher).to_s
  end

  it '#to_s: no message' do
    matcher = Matcher::BlockMatcher.new(-> { true })
    lineno = __LINE__ - 1

    assert_equal "-> { block_matcher_test.rb:#{lineno} }",
      matcher.to_s
    assert_equal "neg(-> { block_matcher_test.rb:#{lineno} })",
      (~matcher).to_s
  end
end
