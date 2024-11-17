# frozen_string_literal: true

require 'test_helper'

describe Matcher::SetMatcher do
  it 'is build by set' do
    matcher = Matcher.build { set([1, 2]) }

    assert_kind_of Matcher::SetMatcher, matcher
  end

  it 'expects an array' do
    matcher = Matcher.build { set([1, 2]) }
    negated = ~matcher

    assert_no_errors matcher.match([2, 1])
    assert_expected_errors negated.match([2, 1]),
      'did not expect object to be an equal set to [1, 2] but got [2, 1]'

    assert_expected_errors matcher.match(nil),
      'expected a kind of Array but got nil'
    assert_no_errors negated.match(nil)
  end

  it 'checks length' do
    matcher = Matcher.build { set([1, 2, 3]) }

    assert_expected_errors matcher.match([1, 2, 3, 4]),
      'expected length of 3 but was 4'
    assert_no_errors matcher.~.match([1, 2, 3, 4])
  end

  it 'matches set of array elements' do
    matcher = Matcher.build { set([1, 2, 3]) }
    negated = ~matcher

    assert_no_errors matcher.match([3, 1, 2])
    assert_expected_errors negated.match([3, 1, 2]),
      'did not expect object to be an equal set to [1, 2, 3] but got [3, 1, 2]'

    assert_expected_errors matcher.match([2, 1]),
      'expected length of 3 but was 2',
      'expected 3 to be included but got [2, 1]'
    assert_no_errors negated.match([2, 1])

    assert_expected_errors matcher.match([1, 2, 4]),
      'expected 3 to be included but got [1, 2, 4]',
      2 => 'did not expect 4 to be included but got [1, 2, 4]'
    assert_no_errors negated.match([1, 2, 4])
  end

  it 'passes parent' do
    matcher = Matcher.build { set([_ == parent]) }
    negated = ~matcher

    self_array = []
    self_array << self_array

    assert_no_errors matcher.match(self_array)
    assert_expected_errors negated.match(self_array),
      'did not expect object to be an equal set to [_ == parent] but got [[...]]'

    assert_expected_errors matcher.match([1]),
      'expected _ == parent to be included but got [1]',
      0 => 'did not expect 1 to be included but got [1]'
    assert_no_errors negated.match([1])
  end

  it '#to_s' do
    matcher = Matcher.build { set([1, 2, 3]) }

    assert_equal 'set([1, 2, 3])', matcher.to_s
    assert_equal '~set([1, 2, 3])', matcher.~.to_s
  end
end
