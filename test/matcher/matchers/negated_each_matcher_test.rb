# frozen_string_literal: true

require 'test_helper'

describe Matcher::NegatedEachMatcher do
  it 'match not each' do
    matcher = ~Matcher::EachMatcher.new(v(1))

    assert_expected_errors matcher.match([1, 1, 1]) do
      _or do
        error(0, 'did not expect 1')
        error(1, 'did not expect 1')
        error(2, 'did not expect 1')
      end
    end

    assert_predicate matcher.match(nil), :valid?
    assert_predicate matcher.match([1, 2, 3]), :valid?
  end

  it '#to_s' do
    matcher = Matcher.build { ~each(1) }

    assert_equal '~each(1)', matcher.to_s
  end
end
