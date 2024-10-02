# frozen_string_literal: true

require 'test_helper'

describe Matcher::NegatedArrayMatcher do
  it 'match not array' do
    matcher = Matcher.build { neg([1, 2, 3]) }

    assert_errors matcher.match([1, 2, 3]) do
      _or do
        error(0, 'expected 1 to not be 1')
        error(1, 'expected 2 to not be 2')
        error(2, 'expected 3 to not be 3')
      end
    end

    assert_predicate matcher.match([1, 2, 4]), :valid?
    assert_predicate matcher.match(nil), :valid?
    assert_predicate matcher.match([]), :valid?
    assert_predicate matcher.match([1, 2, 3, 4]), :valid?
    assert_predicate matcher.match([4, 5, 6]), :valid?
  end

  it '#to_s' do
    matcher = Matcher.build { neg([1, 2, 3]) }

    assert_equal 'neg([1, 2, 3])', matcher.to_s
  end
end
