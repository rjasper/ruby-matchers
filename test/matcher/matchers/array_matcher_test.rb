# frozen_string_literal: true

require 'test_helper'

describe Matcher::ArrayMatcher do
  it 'is built from Array' do
    matcher = Matcher.build { [1, 2] }

    assert_kind_of Matcher::ArrayMatcher, matcher
  end

  it 'expects an Array' do
    matcher = Matcher.build { [1, 2] }

    assert_expected_errors matcher.match(nil),
      'expected a kind of Array but got nil'
    assert_no_errors matcher.~.match(nil)
  end

  it 'detects different length' do
    matcher = Matcher.build { [1, 2] }
    negated = ~matcher

    assert_expected_errors matcher.match([1]),
      'expected length of 2 but was 1'
    assert_no_errors negated.match([1])

    assert_expected_errors matcher.match([1, 2, 3]),
      'expected length of 2 but was 3'
    assert_no_errors negated.match([1, 2, 3])
  end

  it 'matches each element' do
    matcher = Matcher.build { [1, 2, 3] }
    negated = ~matcher

    assert_no_errors matcher.match([1, 2, 3])
    assert_expected_errors negated.match([1, 2, 3]) do
      _or do
        error 0, 'did not expect 1'
        error 1, 'did not expect 2'
        error 2, 'did not expect 3'
      end
    end

    assert_expected_errors matcher.match([4, 5, 6]),
      0 => 'expected 1 but got 4',
      1 => 'expected 2 but got 5',
      2 => 'expected 3 but got 6'
    assert_no_errors negated.match([4, 5, 6])
  end

  it 'passes index' do
    matcher = Matcher.build do
      exp = of(_ == i * 10)

      [exp, exp, exp]
    end

    assert_no_errors matcher.match([0, 10, 20])

    assert_expected_errors matcher.match([0, 11, 20]),
      1 => 'expected _ == i * 10 but got 11 == 10, where i = 1'
  end

  it 'passes parent' do
    matcher = Matcher.build do
      exp = of(parent[i - 1] < parent[i])

      [Integer, exp, exp]
    end

    assert_no_errors matcher.match([1, 3, 5])

    assert_expected_errors matcher.match([1, 5, 3]),
      2 => 'expected parent[i - 1] < parent[i] but got 5 < 3, where parent = [1, 5, 3], i = 2'
  end

  it '#to_s' do
    matcher = Matcher.build { [1, 2, 3] }

    assert_equal '[1, 2, 3]', matcher.to_s
    assert_equal 'neg([1, 2, 3])', matcher.~.to_s
  end
end
