# frozen_string_literal: true

require 'test_helper'

describe Matcher::AnyMatcher do
  it 'match any' do
    values = [1, 2].map { Matcher.of(_1) }
    matcher = Matcher::AnyMatcher.new(values)

    assert_predicate matcher.match(1), :valid?
    assert_predicate matcher.match(2), :valid?
    refute_predicate matcher.match(3), :valid?

    assert_errors matcher.match(4) do
      _or do
        error 'expected 1 but got 4'
        error 'expected 2 but got 4'
      end
    end
  end

  it '#|' do
    matcher = Matcher::AnyMatcher.new([v(1), v(2)]) | v(3)

    assert_equal 'any(1, 2, 3)', matcher.to_s
  end

  it '#to_s' do
    matcher = Matcher::AnyMatcher.new([v(1), v(2)])

    assert_equal 'any(1, 2)', matcher.to_s
    assert_equal 'all(neg(1), neg(2))', (~matcher).to_s
  end
end
