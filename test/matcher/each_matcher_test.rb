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

    test '#inspect' do
      matcher = EachMatcher.new(v(1))

      assert_equal 'each(1)', matcher.inspect
    end
  end
end
