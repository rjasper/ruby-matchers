# frozen_string_literal: true

require 'test_helper'

describe Matcher::ArrayMatcher do
  it 'is built from Array' do
    matcher = Matcher.build { [1, 2] }

    assert_kind_of Matcher::ArrayMatcher, matcher
  end

  it 'expects an Array' do
    matcher = Matcher.build { [1, 2] }

    assert_errors matcher.match(nil),
      msg(nil).not.kind_of(Array)
    assert_no_errors matcher.~.match(nil)
  end

  it 'detects different length' do
    matcher = Matcher.build { [1, 2] }
    negated = ~matcher

    assert_errors matcher.match([1]),
      msg([1]).not.length_of(2, 1)
    assert_no_errors negated.match([1])

    assert_errors matcher.match([1, 2, 3]),
      msg([1, 2, 3]).not.length_of(2, 3)
    assert_no_errors negated.match([1, 2, 3])
  end

  it 'matches each element' do
    matcher = Matcher.build { [1, 2, 3] }
    negated = ~matcher

    assert_no_errors matcher.match([1, 2, 3])
    assert_errors negated.match([1, 2, 3]) do
      _or do
        error 0, msg(1).equal(1)
        error 1, msg(2).equal(2)
        error 2, msg(3).equal(3)
      end
    end

    assert_errors matcher.match([4, 5, 6]),
      0 => msg(4).not.equal(1),
      1 => msg(5).not.equal(2),
      2 => msg(6).not.equal(3)
    assert_no_errors negated.match([4, 5, 6])
  end

  it 'passes index' do
    matcher = Matcher.build do
      exp = of(_ == i * 10)

      [exp, exp, exp]
    end

    assert_no_errors matcher.match([0, 10, 20])

    assert_errors matcher.match([0, 11, 20]),
      1 => 'expected _ == i * 10 but got 11 == 10, where i = 1'
  end

  it 'passes parent' do
    matcher = Matcher.build do
      exp = of(parent[i - 1] < parent[i])

      [Integer, exp, exp]
    end

    assert_no_errors matcher.match([1, 3, 5])

    assert_errors matcher.match([1, 5, 3]),
      2 => 'expected parent[i - 1] < parent[i] but got 5 < 3, where parent = [1, 5, 3], i = 2'
  end

  it '#to_s' do
    matcher = Matcher.build { [1, 2, 3] }

    assert_equal '[1, 2, 3]', matcher.to_s
    assert_equal 'neg([1, 2, 3])', matcher.~.to_s
  end
end
