# frozen_string_literal: true

require 'test_helper'

describe Matcher::NegatedMatcher do
  it 'negates matches' do
    is_one = Matcher.build { 1 }
    matcher = Matcher::NegatedMatcher.new(is_one)

    assert_expected_errors matcher.match(1),
      'did not expect 1 to be valid but got 1'
    assert_predicate matcher.match(2), :valid?
  end

  it '#to_s' do
    is_one = Matcher.build { 1 }
    matcher = Matcher::NegatedMatcher.new(is_one)

    assert_equal 'neg(1)', matcher.to_s
  end
end
