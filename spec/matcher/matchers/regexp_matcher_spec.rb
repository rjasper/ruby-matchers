# frozen_string_literal: true

require "test_helper"

describe Matcher::RegexpMatcher do
  it "is built from Regexp" do
    assert_kind_of(Matcher::RegexpMatcher, Matcher.build { /f/ })
  end

  it "is built by regexp" do
    kind = Matcher::RegexpMatcher

    assert_kind_of(kind, Matcher.build { regexp(/foo/) })
    assert_kind_of(kind, Matcher.build { ~regexp(/foo/) })
    assert_kind_of(kind, Matcher.build { regexp(/foo/, _) })
    assert_kind_of(kind, Matcher.build { ~regexp(/foo/, _) })
    assert_kind_of(kind, Matcher.build { regexp(/foo/) ^ _ })
    assert_kind_of(kind, Matcher.build { ~regexp(/foo/) ^ _ })
  end

  it "matches Regexp" do
    matcher = Matcher.build { /f/ }
    negated = ~matcher

    assert matcher.match?("foo")
    assert_no_errors matcher.match("foo")
    refute negated.match?("foo")
    assert_errors negated.match("foo"),
      msg("foo").matching(/f/)

    refute matcher.match?("bar")
    assert_errors matcher.match("bar"),
      msg("bar").not.matching(/f/)
    assert negated.match?("bar")
    assert_no_errors negated.match("bar")
  end

  it "matches MatchData" do
    matcher = Matcher.build do
      regexp(/x=(\d+)/) ^ project(_[1].to_i) ^ (_ > 10)
    end

    negated = ~matcher
    key = expression { _.match(/x=(\d+)/)[1].to_i }

    assert matcher.match?("x=20")
    assert_no_errors matcher.match("x=20")
    refute negated.match?("x=20")
    assert_errors negated.match("x=20"),
      key => msg(20).greater_than(10)

    refute matcher.match?("x=5")
    assert_errors matcher.match("x=5"),
      key => msg(5).not.greater_than(10)
    assert negated.match?("x=5")
    assert_no_errors negated.match("x=5")

    refute matcher.match?("y=5")
    assert_errors matcher.match("y=5"),
      msg("y=5").not.matching(/x=(\d+)/)
    assert negated.match?("y=5")
    assert_no_errors negated.match("y=5")

    refute matcher.match?(5)
    assert_errors matcher.match(5),
      msg(5).not.kind_of(String)
    assert negated.match?(5)
    assert_no_errors negated.match(5)
  end

  it "#to_s" do
    matcher = Matcher::RegexpMatcher.new(/asdf/)

    assert_equal "/asdf/", matcher.to_s
    assert_equal "neg(/asdf/)", matcher.~.to_s
  end

  it "#to_s: with matcher" do
    matcher = Matcher.build do
      regexp(/x=(\d+)/) ^ project(_[1].to_i) ^ (_ > 10)
    end

    assert_equal 'regexp(/x=(\\d+)/, project(actual[1].to_i => actual > 10))',
      matcher.to_s
    assert_equal '~regexp(/x=(\\d+)/, project(actual[1].to_i => actual > 10))',
      matcher.~.to_s
  end
end
