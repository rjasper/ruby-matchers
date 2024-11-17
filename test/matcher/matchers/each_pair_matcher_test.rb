# frozen_string_literal: true

require 'test_helper'

describe Matcher::EachPairMatcher do
  it 'is built by each_pair' do
    matcher = Matcher.build do
      each_pair(key == value.to_sym)
    end

    assert_kind_of Matcher::EachPairMatcher, matcher
  end

  it 'expects an object responding to :each_pair' do
    matcher = Matcher.build do
      each_pair([:key, 'value'])
    end

    assert_errors matcher.match(nil),
      "expected an object responding to `each_pair' but got nil"
    assert_no_errors matcher.~.match(nil)
  end

  it 'matches each pair' do
    matcher = Matcher.build do
      each_pair(key == value.to_s)
    end

    negated = ~matcher

    assert_no_errors matcher.match({ '1' => 1, 'a' => :a })
    assert_errors negated.match({ '1' => 1, 'a' => :a }) do
      _or do
        error '1', 'expected k != v.to_s but got "1" != "1", where v = 1'
        error 'a', 'expected k != v.to_s but got "a" != "a", where v = :a'
      end
    end

    assert_errors matcher.match({ '1' => 1, 'a' => :a, 0 => '0' }),
      0 => 'expected k == v.to_s but got 0 == "0", where v = "0"'
    assert_no_errors negated.match({ '1' => 1, 'a' => :a, 0 => '0' })
  end

  it '#to_s' do
    matcher = Matcher.build { each_pair({ 'a' => 1 }) }

    assert_equal 'each_pair({"a"=>1})', matcher.to_s
    assert_equal '~each_pair({"a"=>1})', matcher.~.to_s
  end
end
