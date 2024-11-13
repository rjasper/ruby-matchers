# frozen_string_literal: true

require 'test_helper'

describe Matcher::NegatedArrayMatcher do
  it 'match not array' do
    matcher = Matcher.build { neg([1, 2, 3]) }

    assert_expected_errors matcher.match([1, 2, 3]) do
      _or do
        error(0, 'did not expect 1')
        error(1, 'did not expect 2')
        error(2, 'did not expect 3')
      end
    end

    assert_no_errors matcher.match([1, 2, 4])
    assert_no_errors matcher.match(nil)
    assert_no_errors matcher.match([])
    assert_no_errors matcher.match([1, 2, 3, 4])
    assert_no_errors matcher.match([4, 5, 6])
  end

  it '#to_s' do
    matcher = Matcher.build { neg([1, 2, 3]) }

    assert_equal 'neg([1, 2, 3])', matcher.to_s
  end
end
