# frozen_string_literal: true

require 'test_helper'

describe Matcher::SetMatcher do
  it 'match array' do
    matcher = Matcher::SetMatcher.new([v(1), v(2), v(3)])

    assert_predicate matcher.match([3, 1, 2]), :valid?
    assert_expected_errors matcher.match(nil),
      'expected a kind of Array but got nil'
    assert_expected_errors matcher.match([]),
      'expected length of 3 but got 0',
      'expected 1 to be included but got []',
      'expected 2 to be included but got []',
      'expected 3 to be included but got []'
    assert_expected_errors matcher.match([1, 2, 3, 4]),
      'expected length of 3 but got 4'
    assert_expected_errors matcher.match([1, 2, 4]),
      'expected 3 to be included but got [1, 2, 4]',
      2 => 'did not expect 4 to be included but got [1, 2, 4]'

    negated = ~matcher

    assert_expected_errors negated.match([3, 1, 2]),
      'did not expect [3, 1, 2] to be an equal set to [1, 2, 3]'

    assert_predicate negated.match(nil), :valid?
    assert_predicate negated.match([]), :valid?
    assert_predicate negated.match([1, 2, 3, 4]), :valid?
    assert_predicate negated.match([1, 2, 4]), :valid?
  end

  it 'pass parent' do
    matcher = Matcher.build do
      set([_ == parent])
    end

    self_array = []
    self_array << self_array

    assert_predicate matcher.match(self_array), :valid?

    assert_expected_errors matcher.match([1]),
      'expected _ == parent to be included in [1]',
      0 => 'did not expect 1 to be included but got [1]'
  end

  it '#to_s' do
    assert_equal 'set([1, 2, 3])', Matcher::SetMatcher.new([v(1), v(2), v(3)]).to_s
  end
end
