# frozen_string_literal: true

require 'test_helper'

describe Matcher::Optional do
  it 'is built by optional' do
    assert_kind_of(Matcher::Optional, Matcher.build { break optional(1) })
  end

  it '#==' do
    assert Matcher::Optional.new(1) == Matcher::Optional.new(1)
    refute Matcher::Optional.new(1) == Matcher::Optional.new(2)
  end

  it 'works as hash key' do
    o1_a = Matcher::Optional.new(1)
    o1_b = Matcher::Optional.new(1)
    o2_a = Matcher::Optional.new(2)
    o2_b = Matcher::Optional.new(2)

    hash = { o1_a => 1, o2_a => 2 }

    assert_equal 1, hash[o1_b]
    assert_equal 2, hash[o2_b]
  end

  it '#to_s' do
    assert_equal 'optional(:foo)', Matcher::Optional.new(:foo).to_s
  end
end
