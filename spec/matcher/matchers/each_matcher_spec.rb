# frozen_string_literal: true

require 'test_helper'

describe Matcher::EachMatcher do
  it 'is built by each' do
    assert_kind_of Matcher::EachMatcher,
      (Matcher.build { each(Integer) })
    assert_kind_of Matcher::EachMatcher,
      (Matcher.build { each ^ Integer })
  end

  it 'expects an object responding to :each' do
    matcher = Matcher.build { each(Integer) }

    assert_errors matcher.match(nil),
      msg(nil).not.responding_to(:each)
    assert_no_errors matcher.~.match(nil)
  end

  it 'matches each' do
    matcher = Matcher.build { each(1) }
    negated = ~matcher

    assert_no_errors matcher.match([1, 1])
    assert_errors negated.match([1, 1]) do
      _or do
        error 0, msg(1).equal(1)
        error 1, msg(1).equal(1)
      end
    end

    assert_errors matcher.match([1, 2, 3]),
      1 => msg(2).not.equal(1),
      2 => msg(3).not.equal(1)
    assert_no_errors negated.match([1, 2, 3])
  end

  it 'passes index' do
    matcher = Matcher.build do
      each(_ == i.to_s)
    end

    assert_errors matcher.match(['0', '1', '3']),
      2 => 'expected _ == i.to_s but got "3" == "2", where i = 2'
  end

  it 'passes parent' do
    matcher = Matcher.build do
      each(_ == parent.length * 10 + index + 1)
    end

    assert_errors matcher.match([41, 42, 43, 45]),
      3 => 'expected _ == parent.length * 10 + i + 1 but got 45 == 44, where parent = [41, 42, 43, 45], i = 3'
  end

  it '#to_s' do
    matcher = Matcher.build { each(1) }

    assert_equal 'each(1)', matcher.to_s
    assert_equal '~each(1)', matcher.~.to_s
  end
end
