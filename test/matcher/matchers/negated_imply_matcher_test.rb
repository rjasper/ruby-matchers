# frozen_string_literal: true

require 'test_helper'

describe Matcher::NegatedImplyMatcher do
  it 'match negated imply' do
    matcher = Matcher.build do
      ~imply(String, _.downcase == _)
    end

    assert_errors matcher.match('hello'),
      'expected _.downcase to not be _ ("hello")'
    assert_errors matcher.match(1),
      'expected 1 to be kind of String'
    assert_predicate matcher.match('Hello'), :valid?
  end

  it '#to_s' do
    matcher = Matcher.build do
      ~imply(String, 'string')
    end

    assert_equal '~imply(String, "string")', matcher.to_s
  end
end
