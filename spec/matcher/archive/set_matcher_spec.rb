# frozen_string_literal: true

require 'test_helper'
require 'matcher/archive/set_matcher'

describe Matcher::SetMatcher do
  it 'is build by set' do
    matcher = Matcher.build { set([1, 2]) }

    assert_kind_of Matcher::SetMatcher, matcher
  end

  it 'expects an array' do
    matcher = Matcher.build { set([1, 2]) }
    negated = ~matcher

    assert_no_errors matcher.match([2, 1])
    assert_errors negated.match([2, 1]),
      'did not expect object to be an equal set to [1, 2] but got [2, 1]'

    assert_errors matcher.match(nil),
      msg(nil).not.kind_of(Array)
    assert_no_errors negated.match(nil)
  end

  it 'checks length' do
    matcher = Matcher.build { set([1, 2, 3]) }

    assert_errors matcher.match([1, 2, 3, 4]),
      msg([1, 2, 3, 4]).not.length_of(3, 4)
    assert_no_errors matcher.~.match([1, 2, 3, 4])
  end

  it 'matches set of array elements' do
    matcher = Matcher.build { set([1, 2, 3]) }
    negated = ~matcher

    assert_no_errors matcher.match([3, 1, 2])
    assert_errors negated.match([3, 1, 2]),
      'did not expect object to be an equal set to [1, 2, 3] but got [3, 1, 2]'

    assert_errors matcher.match([2, 1]),
      msg([2, 1]).not.length_of(3, 2),
      'expected to include an element matching 3 but got [2, 1]'
    assert_no_errors negated.match([2, 1])

    assert_errors matcher.match([1, 2, 4]),
      'expected to include an element matching 3 but got [1, 2, 4]',
      2 => msg([1, 2, 4]).including(4)
    assert_no_errors negated.match([1, 2, 4])
  end

  it 'passes parent' do
    matcher = Matcher.build { set([_ == parent]) }
    negated = ~matcher

    self_array = []
    self_array << self_array

    assert_no_errors matcher.match(self_array)
    assert_errors negated.match(self_array),
      'did not expect object to be an equal set to [actual == parent] but got [[...]]'

    assert_errors matcher.match([1]),
      'expected to include an element matching actual == parent but got [1]',
      0 => msg([1]).including(1)
    assert_no_errors negated.match([1])
  end

  it '#to_s' do
    matcher = Matcher.build { set([1, 2, 3]) }

    assert_equal 'set([1, 2, 3])', matcher.to_s
    assert_equal '~set([1, 2, 3])', matcher.~.to_s
  end
end
