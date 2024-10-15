# frozen_string_literal: true

require 'test_helper'

describe Matcher::NegatedImplyMatcher do
  it 'match negated imply' do
    matcher = Matcher.build do
      ~imply(String, _.downcase == _)
    end

    assert_expected_errors matcher.match('hello'),
      'expected _.downcase to not be _ ("hello")'
    assert_expected_errors matcher.match(1),
      'expected a kind of String but got 1'
    assert_predicate matcher.match('Hello'), :valid?
  end

  it '#to_s' do
    matcher = Matcher.build do
      ~imply(String, 'string')
    end

    assert_equal '~imply(String, "string")', matcher.to_s
  end
end
