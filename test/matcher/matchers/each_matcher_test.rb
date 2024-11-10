# frozen_string_literal: true

require 'test_helper'

describe Matcher::EachMatcher do
  it 'match each' do
    matcher = Matcher::EachMatcher.new(v(1))

    assert_predicate matcher.match([1, 1, 1]), :valid?
    assert_expected_errors matcher.match(nil),
      "expected an object responding to `each' but got nil"
    assert_expected_errors matcher.match([1, 2, 3]),
      1 => 'expected 1 but got 2',
      2 => 'expected 1 but got 3'
  end

  it 'pass index' do
    matcher = Matcher.build do
      each(_ == i.to_s)
    end

    assert_expected_errors matcher.match(['0', '1', '3']),
      2 => 'expected _ == i.to_s but got "3" == "2", where i = 2'
  end

  it 'pass parent' do
    matcher = Matcher.build do
      each(_ == parent.length * 10 + index + 1)
    end

    assert_expected_errors matcher.match([41, 42, 43, 45]),
      3 => 'expected _ == parent.length * 10 + i + 1 but got 45 == 44, where parent = [41, 42, 43, 45], i = 3'
  end

  it '#to_s' do
    matcher = Matcher::EachMatcher.new(v(1))

    assert_equal 'each(1)', matcher.to_s
  end
end
