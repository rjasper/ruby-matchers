# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::NegatedEachPairMatcher do
  it 'match not each pair' do
    matcher = Matcher.build do
      ~each_pair(key == value.to_s)
    end

    assert_errors matcher.match({ '1' => 1, 'a' => :a }) do
      _or do
        error '1', 'expected k to not be v.to_s ("1") for v = 1'
        error 'a', 'expected k to not be v.to_s ("a") for v = :a'
      end
    end

    assert_predicate matcher.match({ '1' => 1, 'a' => :a, 0 => '0' }), :valid?
  end

  it '#to_s' do
    matcher = Matcher.build { ~each_pair({ 'a' => 1 }) }

    assert_equal '~each_pair({"a"=>1})', matcher.to_s
  end
end
