# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class BlockMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'validates blocks' do
      matcher = BlockMatcher.new(-> { _1 > 2 }, nil)

      assert_predicate matcher.match(4), :valid?
      assert_not_predicate matcher.match(0), :valid?
    end

    test 'generates message' do
      matcher = BlockMatcher.new(-> { _1 == 42 }, 'an answer to everything')

      assert_errors matcher.match(3),
        'expected an answer to everything but got 3'
    end

    test '#inspect: with message' do
      matcher = BlockMatcher.new(-> { _1 % 3 == 0 }, 'a number divisible by three')

      assert_equal 'a number divisible by three', matcher.inspect
    end

    test '#inspect: no message' do
      matcher = BlockMatcher.new(-> { true })
      lineno = __LINE__ - 1

      assert_equal "-> { block_matcher_test.rb:#{lineno} }",
        matcher.inspect
    end
  end
end
