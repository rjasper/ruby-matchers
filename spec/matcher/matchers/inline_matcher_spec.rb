# frozen_string_literal: true

require "test_helper"

describe Matcher::InlineMatcher do
  it "is built from inline" do
    assert_kind_of(Matcher::InlineMatcher, Matcher.build { inline { errors << "dummy" } })
  end

  it "matches inline implementation" do
    matcher = Matcher.build do
      inline(negatable: true) do
        errors << expected.not_if(negated).described_by("a number") if
          negated == actual.is_a?(Numeric)
      end
    end

    negated = ~matcher

    assert matcher.match?(1)
    assert_no_errors matcher.match(1)
    refute negated.match?(1)
    assert_errors negated.match(1),
      msg(1).described_by("a number")

    refute matcher.match?("foo")
    assert_errors matcher.match("foo"),
      msg("foo").not.described_by("a number")
    assert negated.match?("foo")
    assert_no_errors negated.match("foo")
  end

  it "forwards to given matcher" do
    matcher = Matcher.build do
      inline(_ > 0, negatable: true) do
        errors << _yield(self.matcher)
      end
    end

    negated = ~matcher

    assert matcher.match?(10)
    assert_no_errors matcher.match(10)
    refute negated.match?(10)
    assert_errors negated.match(10),
      msg(10).greater_than(0)

    refute matcher.match?(-5)
    assert_errors matcher.match(-5),
      msg(-5).not.greater_than(0)
    assert negated.match?(-5)
    assert_no_errors negated.match(-5)
  end

  it "falls back to negated behaviour" do
    matcher = Matcher.build do
      inline { errors << "falsy" unless actual }
    end

    negated = ~matcher

    assert negated.match?(false)
    assert_no_errors negated.match(false)
    refute negated.match?(true)
    assert_errors negated.match(true),
      msg(true).namespace(:negated).valid(matcher)
  end

  it "#to_s" do
    lineno = __LINE__ + 2
    matcher = Matcher.build do
      inline(negatable: true) { errors << "dummy" }
    end

    assert_equal "inline { inline_matcher_spec.rb:#{lineno} }", matcher.to_s
    assert_equal "~inline { inline_matcher_spec.rb:#{lineno} }", matcher.~.to_s

    lineno = __LINE__ + 2
    matcher = Matcher.build do
      inline(_.even?, negatable: true) { errors << "dummy" }
    end

    assert_equal "inline(actual.even?) { inline_matcher_spec.rb:#{lineno} }", matcher.to_s
    assert_equal "~inline(actual.even?) { inline_matcher_spec.rb:#{lineno} }", matcher.~.to_s
  end
end
