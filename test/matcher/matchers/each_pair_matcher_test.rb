# frozen_string_literal: true

require 'test_helper'

describe Matcher::EachPairMatcher do
  it 'match each pair' do
    matcher = Matcher.build do
      each_pair(key == value.to_s)
    end

    assert_predicate matcher.match({ '1' => 1, 'a' => :a }), :valid?

    assert_expected_errors matcher.match([1, 2, 3]),
      "expected an object responding to `each_pair' but got [1, 2, 3]"
    assert_expected_errors matcher.match({ '1' => 1, 'a' => :a, 0 => '0' }),
      0 => 'expected k == v.to_s but got 0 == "0", where v = "0"'
  end

  it '#to_s' do
    matcher = Matcher::EachPairMatcher.new({ 'a' => 1 })

    assert_equal 'each_pair({"a"=>1})', matcher.to_s
  end
end
