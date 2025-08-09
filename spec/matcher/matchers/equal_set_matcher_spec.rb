# frozen_string_literal: true

require 'test_helper'

describe Matcher::EqualSetMatcher do
  it 'is built by equal_set' do
    matcher = Matcher.build { equal_set(1, vars[:foo]) }

    assert_kind_of Matcher::EqualSetMatcher, matcher
  end

  it 'matches array like a set' do
    matcher = Matcher.build { equal_set(1, 2, 3) }
    negated = ~matcher

    assert_no_errors matcher.match([3, 1, 2])
    assert_errors negated.match([3, 1, 2]),
      msg([3, 1, 2]).namespace(:set).equal([1, 2, 3])

    assert_errors matcher.match([3, 1]),
      msg([3, 1]).not.including(2)
    assert_no_errors negated.match([3, 1])

    assert_errors matcher.match([3, 1, 2, 4]),
      3 => msg(4).in([3, 1, 2, 4])
    assert_no_errors negated.match([3, 1, 2, 4])

    assert_errors matcher.match([]),
      msg([]).not.including(1),
      msg([]).not.including(2),
      msg([]).not.including(3)
    assert_no_errors negated.match([])

    assert_errors matcher.match([1, 3, 2, 1]),
      3 => msg(1).duplicate(0)
    assert_no_errors negated.match([1, 3, 2, 1])

    assert_errors matcher.match(nil),
      msg(nil).not.responding_to(:each)
    assert_no_errors negated.match(nil)
  end

  it 'matches empty array' do
    matcher = Matcher.build { equal_set }
    negated = ~matcher

    assert_no_errors matcher.match([])
    assert_errors negated.match([]),
      msg([]).namespace(:set).equal([])

    assert_errors matcher.match([1]),
      0 => msg(1).in([1])
    assert_no_errors negated.match([1])
  end

  it '#to_s' do
    assert_equal 'equal_set(1, foo)',
      Matcher.build { equal_set(1, vars[:foo]) }.to_s
    assert_equal '~equal_set(1, foo)',
      Matcher.build { ~equal_set(1, vars[:foo]) }.to_s
  end
end
