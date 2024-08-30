# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class AnyMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match any' do
      values = [1, 2].map { Matcher.of(_1) }
      matcher = AnyMatcher.new(values)

      assert_predicate matcher.match(1), :valid?
      assert_predicate matcher.match(2), :valid?
      assert_not_predicate matcher.match(3), :valid?

      assert_errors matcher.match(4) do
        _or do
          error 'expected 1 but got 4'
          error 'expected 2 but got 4'
        end
      end
    end

    test '#|' do
      matcher = AnyMatcher.new([v(1), v(2)]) | v(3)

      assert_equal 'any(1, 2, 3)', matcher.inspect
    end

    test '#inspect' do
      matcher = AnyMatcher.new([v(1), v(2)])

      assert_equal 'any(1, 2)', matcher.inspect
    end
  end
end
