# frozen_string_literal: true

require 'test_helper'

describe Matcher::BlockMatcher do
  it 'is built by satisfy and from Proc' do
    assert_kind_of(Matcher::BlockMatcher, Matcher.build { satisfy { _1 > 2 } })
    assert_kind_of(Matcher::BlockMatcher, Matcher.build { -> { _1 > 2 } })
  end

  it 'matches without description' do
    lineno = __LINE__ + 2
    matcher = Matcher.build do
      satisfy { _1 > 2 }
    end

    negated = ~matcher

    assert matcher.match?(4)
    assert_no_errors matcher.match(4)

    refute negated.match?(4)
    assert_errors negated.match(4),
      "did not expect to satisfy condition block_matcher_spec.rb:#{lineno} but got 4"

    refute matcher.match?(0)
    assert_errors matcher.match(0),
      "expected to satisfy condition block_matcher_spec.rb:#{lineno} but got 0"

    assert negated.match?(0)
    assert_no_errors negated.match(0)
  end

  it 'matches with description' do
    matcher = Matcher.build do
      satisfy('an answer to everything') { _1 == 42 }
    end

    negated = ~matcher

    assert_no_errors matcher.match(42)
    assert_errors negated.match(42),
      msg(42).described_by('an answer to everything')

    assert_errors matcher.match(3),
      msg(3).not.described_by('an answer to everything')
    assert_no_errors negated.match(3)
  end

  it '#to_s: with description' do
    matcher = Matcher.build do
      satisfy('a number divisible by three') { _1 % 3 == 0 }
    end

    assert_equal 'a number divisible by three', matcher.to_s
    assert_equal 'neg(a number divisible by three)', (~matcher).to_s
  end

  it '#to_s: without description' do
    lineno = __LINE__ + 2
    matcher = Matcher.build do
      satisfy { true }
    end

    assert_equal "-> { block_matcher_spec.rb:#{lineno} }",
      matcher.to_s
    assert_equal "neg(-> { block_matcher_spec.rb:#{lineno} })",
      (~matcher).to_s
  end
end
