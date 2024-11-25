# frozen_string_literal: true

require 'test_helper'

describe Matcher::List do
  describe 'empty' do
    it '#==' do
      assert_operator empty, :==, empty
    end

    it '#<<' do
      assert_equal [1], (empty << 1).to_a
    end

    it '#empty?' do
      assert_predicate empty, :empty?
    end

    it '#last' do
      assert_nil empty.last
    end

    it '#each' do
      assert_equal [], empty.enum_for(:each).to_a
    end

    it '#to_s' do
      assert_equal '[]', empty.to_s
    end
  end

  describe 'one' do
    it 'same as empty << elem' do
      assert_equal (empty << 1), one(1)
    end
  end

  describe 'non empty' do
    it '#==' do
      assert_operator (empty << 1 << 2 << 3), :==, (empty << 1 << 2 << 3)
      refute_operator (empty << 1 << 2 << 3), :==, (empty << 1 << 2 << 4)
    end

    it '#<<' do
      assert_equal [3, 2, 1], (empty << 1 << 2 << 3).to_a
    end

    it '#last' do
      assert_equal 1, (empty << 1 << 2 << 3).last
    end

    it '#each' do
      assert_equal [2, 1], (empty << 1 << 2).enum_for(:each).to_a
    end

    it '#reverse_each' do
      list = empty << 1 << 2 << 3

      assert_equal [1, 2, 3], list.enum_for(:reverse_each).to_a
    end

    it 'can be used in hashes' do
      hash = { one(1) => 1, one(2) => 2 }

      assert_equal 1, hash[one(1)]
      assert_equal 2, hash[one(2)]
    end
  end

  private

  def empty
    Matcher::List.empty
  end

  def one(elem)
    Matcher::List.one(elem)
  end
end
