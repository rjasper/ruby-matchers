# frozen_string_literal: true

require "test_helper"

describe Matcher::NegatedMatcher do
  it "negates matches" do
    is_one = Matcher.build { 1 }
    matcher = Matcher::NegatedMatcher.new(is_one)

    refute matcher.match?(1)
    assert_errors matcher.match(1),
      "did not expect 1 to be valid but got 1"
    assert matcher.match?(2)
    assert_no_errors matcher.match(2)
  end

  it "#to_s" do
    is_one = Matcher.build { 1 }
    matcher = Matcher::NegatedMatcher.new(is_one)

    assert_equal "neg(1)", matcher.to_s
  end
end
