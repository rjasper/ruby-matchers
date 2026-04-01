# frozen_string_literal: true

require 'test_helper'

describe Matcher::Optional do
  describe 'optional helper' do
    it 'builds Optional' do
      assert_kind_of(Matcher::Optional, Matcher.build { break optional(1) })
    end

    it 'converts recorder to expression' do
      assert_equal(1, Matcher.build { break optional(1).value })

      expected = Matcher::Variable.actual

      assert_equal(expected, Matcher.build { break optional(_).value })
    end
  end

  it '#==' do
    assert_equal Matcher::Optional.new([1]), Matcher::Optional.new([1])
    refute_equal Matcher::Optional.new([1]), Matcher::Optional.new([2])
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
