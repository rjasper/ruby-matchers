# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::EachPairMatcher do
  it 'match each pair' do
    matcher = Matcher.build do
      each_pair(key == value.to_s)
    end

    assert_predicate matcher.match({ '1' => 1, 'a' => :a }), :valid?
    assert_errors matcher.match({ '1' => 1, 'a' => :a, 0 => '0' }),
      0 => 'expected k to be v.to_s ("0") but got 0 for v = "0"'
  end

  it '#to_s' do
    matcher = Matcher::EachPairMatcher.new({ 'a' => 1 })

    assert_equal 'each_pair({"a"=>1})', matcher.to_s
  end
end
