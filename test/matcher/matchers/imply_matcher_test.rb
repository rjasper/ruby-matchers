# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class ImplyMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match imply' do
      matcher = Matcher.build do
        imply(String, 'string')
      end

      assert_predicate matcher.match('string'), :valid?
      assert_not_predicate matcher.match('foo'), :valid?
      assert_predicate matcher.match(1), :valid?
    end

    test 'match negated imply' do
      matcher = ~Matcher.build do
        imply(String, _.downcase == _)
      end

      assert_errors matcher.match('hello'),
        'expected _.downcase to not be _ ("hello")'
      assert_errors matcher.match(1),
        'expected 1 to be kind of String'
      assert_predicate matcher.match('Hello'), :valid?
    end

    test '#inspect' do
      matcher = Matcher.build do
        imply(String, 'string')
      end

      assert_equal 'imply(String, "string")', matcher.inspect
    end
  end
end
