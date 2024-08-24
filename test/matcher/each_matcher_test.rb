# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class EachMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match each' do
      matcher = EachMatcher.new(v(1))

      assert_predicate matcher.match([1, 1, 1]), :valid?
      assert_errors matcher.match(nil),
        'expected to respond to "each" but got nil'
      assert_errors matcher.match([1, 2, 3]),
        1 => 'expected 1 but got 2',
        2 => 'expected 1 but got 3'
    end

    test 'match each entry' do
      matcher = Matcher.build do
        each(key == value.to_s)
      end

      assert_predicate matcher.match({ '1' => 1, 'a' => :a }), :valid?
      assert_errors matcher.match({ '1' => 1, 'a' => :a, 0 => '0' }),
        0 => 'expected k to be v.to_s ("0") but got 0 for v = "0"'
    end

    test 'pass index' do
      matcher = Matcher.build do
        each(_ == i.to_s)
      end

      assert_errors matcher.match(['0', '1', '3']),
        2 => 'expected _ to be i.to_s ("2") but got "3" for i = 2'
    end

    test 'pass parent' do
      matcher = Matcher.build do
        each(_ == parent.length * 10 + index + 1)
      end

      assert_errors matcher.match([41, 42, 43, 45]),
        3 => 'expected _ to be parent.length * 10 + i + 1 (44) but got 45 for parent = [41, 42, 43, 45], i = 3'
    end

    test '#inspect' do
      matcher = EachMatcher.new(v(1))

      assert_equal 'each(1)', matcher.inspect
    end
  end
end
