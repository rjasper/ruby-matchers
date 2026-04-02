# frozen_string_literal: true

require "test_helper"

describe Matcher::ImplyMatcher do
  it "is built by imply" do
    assert_kind_of(Matcher::ImplyMatcher, Matcher.build { imply(Integer, 1) })
    assert_kind_of(Matcher::ImplyMatcher, Matcher.build { imply(Integer) ^ 1 })
  end

  it "matches against implied matchers" do
    matcher = Matcher.build { imply(String, "string") }
    negated = ~matcher

    assert matcher.match?("string")
    assert_no_errors matcher.match("string")
    refute negated.match?("string")
    assert_errors negated.match("string"),
      msg("string").equal("string")

    refute matcher.match?("foo")
    assert_errors matcher.match("foo"),
      msg("foo").not.equal("string")
    assert negated.match?("foo")
    assert_no_errors negated.match("foo")

    assert matcher.match?(1)
    assert_no_errors matcher.match(1)
    refute negated.match?(1)
    assert_errors negated.match(1),
      msg(1).not.kind_of(String)
  end

  it "evaluates expression condition" do
    matcher = Matcher.build do
      imply(_.even?, 42)
    end

    assert matcher.match?(42)
    assert_no_errors matcher.match(42)
    assert matcher.match?(3)
    assert_no_errors matcher.match(3)
    assert matcher.match?(nil)
    assert_no_errors matcher.match(nil)

    refute matcher.match?(2)
    assert_errors matcher.match(2),
      msg(2).not.equal(42)
  end

  it "#>>" do
    matcher = Matcher.build { of(Integer) >> 1 }

    assert_equal "imply(Integer, 1)", matcher.to_s
  end

  it "#to_s" do
    matcher = Matcher.build { imply(String, "string") }

    assert_equal 'imply(String, "string")', matcher.to_s
    assert_equal '~imply(String, "string")', matcher.~.to_s
  end
end
