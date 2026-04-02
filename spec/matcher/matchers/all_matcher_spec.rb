# frozen_string_literal: true

require "test_helper"

describe Matcher::AllMatcher do
  it "is built by all" do
    matcher = Matcher.build { all(_ > 1, _ < 10) }

    assert_kind_of Matcher::AllMatcher, matcher
  end

  it "matches all" do
    matcher = Matcher.build do
      all(
        satisfy("a number divisible by 3") { _1 % 3 == 0 },
        satisfy("an even number", &:even?),
      )
    end

    negated = ~matcher

    assert matcher.match?(6)
    assert_no_errors matcher.match(6)
    refute negated.match?(6)
    assert_errors negated.match(6) do
      _or do
        error msg(6).described_by("a number divisible by 3")
        error msg(6).described_by("an even number")
      end
    end

    refute matcher.match?(9)
    assert_errors matcher.match(9),
      msg(9).not.described_by("an even number")
    assert negated.match?(9)
    assert_no_errors negated.match(9)

    refute matcher.match?(4)
    assert_errors matcher.match(4),
      msg(4).not.described_by("a number divisible by 3")
    assert negated.match?(4)
    assert_no_errors negated.match(4)

    refute matcher.match?(5)
    assert_errors matcher.match(5),
      msg(5).not.described_by("a number divisible by 3"),
      msg(5).not.described_by("an even number")
    assert negated.match?(5)
    assert_no_errors negated.match(5)
  end

  it "#~" do
    matcher = Matcher.build { ~all(1, 2) }

    assert_equal "any(neg(1), neg(2))", matcher.to_s
  end

  it "#*" do
    assert_equal "all(1, 2, 3)",
      Matcher.build { all(1, 2) * 3 }.to_s
    assert_equal "all(1, 2, 3)",
      Matcher.build { of(1) * all(2, 3) }.to_s
    assert_equal "all(1, 2)",
      Matcher.build { of(1) * 2 }.to_s
  end

  it "#to_s" do
    matcher = Matcher.build { all(1, 2) }

    assert_equal "all(1, 2)", matcher.to_s
  end
end
