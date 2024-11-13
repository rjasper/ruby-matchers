# frozen_string_literal: true

require 'test_helper'

describe Matcher::ImplyMatcher do
  it 'match imply' do
    matcher = Matcher.build do
      imply(String, 'string')
    end

    assert_no_errors matcher.match('string')
    refute_predicate matcher.match('foo'), :valid?
    assert_no_errors matcher.match(1)
  end

  it 'match negated imply' do
    matcher = ~Matcher.build do
      imply(String, _.downcase == _)
    end

    assert_expected_errors matcher.match('hello'),
      'expected _.downcase != _ but got "hello" != "hello"'
    assert_expected_errors matcher.match(1),
      'expected a kind of String but got 1'
    assert_no_errors matcher.match('Hello')
  end

  it '#to_s' do
    matcher = Matcher.build do
      imply(String, 'string')
    end

    assert_equal 'imply(String, "string")', matcher.to_s
  end
end
