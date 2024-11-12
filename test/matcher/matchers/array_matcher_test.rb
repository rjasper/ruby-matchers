# frozen_string_literal: true

require 'test_helper'

describe Matcher::ArrayMatcher do
  it 'expects an Array' do
    errors = match(nil) { [1, 2]}

    assert_errors errors, msg_not(:kind_of, nil, Array)
    assert_expected_errors errors, 'expected a kind of Array but got nil'
  end

  it 'detects different length' do
    matcher = Matcher.build { [1, 2] }

    errors = matcher.match([1])

    assert_errors errors, msg_not(:length_of, [1], 2, 1)
    assert_expected_errors errors, 'expected length of 2 but was 1'

    assert_errors matcher.match([1, 2, 3]), msg_not(:length_of, [1, 2, 3], 2, 3)
  end

  it 'match array' do
    matcher = Matcher::ArrayMatcher.new([v(1), v(2), v(3)])

    assert_predicate matcher.match([1, 2, 3]), :valid?
    assert_expected_errors matcher.match(nil),
      'expected a kind of Array but got nil'
    assert_expected_errors matcher.match([]),
      'expected length of 3 but was 0'
    assert_expected_errors matcher.match([1, 2, 3, 4]),
      'expected length of 3 but was 4'
    assert_expected_errors matcher.match([4, 5, 6]),
      0 => 'expected 1 but got 4',
      1 => 'expected 2 but got 5',
      2 => 'expected 3 but got 6'
  end

  it 'pass index' do
    exp = expression { _ == i * 10 }
    item_matcher = Matcher.of(exp)

    matcher = Matcher::ArrayMatcher.new([item_matcher, item_matcher, item_matcher])

    assert_predicate matcher.match([0, 10, 20]), :valid?
    assert_expected_errors matcher.match([0, 11, 20]),
      1 => 'expected _ == i * 10 but got 11 == 10, where i = 1'
  end

  it 'pass parent' do
    item_matcher = Matcher.build do
      parent[i - 1] < parent[i]
    end

    matcher = Matcher::ArrayMatcher.new([Matcher.of(Integer), item_matcher, item_matcher])

    assert_predicate matcher.match([1, 3, 5]), :valid?
    assert_expected_errors matcher.match([1, 5, 3]),
      2 => 'expected parent[i - 1] < parent[i] but got 5 < 3, where parent = [1, 5, 3], i = 2'
  end

  it '#to_s' do
    matcher = Matcher::ArrayMatcher.new([v(1), v(2), v(3)])

    assert_equal '[1, 2, 3]', matcher.to_s
  end
end
