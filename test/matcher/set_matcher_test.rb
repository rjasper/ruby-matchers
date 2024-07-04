# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class SetMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match array' do
      matcher = SetMatcher.new([v(1), v(2), v(3)])

      assert_predicate matcher.match([3, 1, 2]), :valid?
      assert_errors matcher.match(nil),
        'expected an Array but got nil'
      assert_errors matcher.match([]),
        'expected length of 3 but got 0'
      assert_errors matcher.match([1, 2, 3, 4]),
        'expected length of 3 but got 4'
      assert_errors matcher.match([1, 2, 4]),
        'expected array to include 3',
        2 => 'unexpected item 4'
    end

    test '#inspect' do
      assert_equal 'set([1, 2, 3])', SetMatcher.new([v(1), v(2), v(3)]).inspect
    end
  end
end
