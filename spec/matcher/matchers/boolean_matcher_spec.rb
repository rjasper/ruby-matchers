# frozen_string_literal: true

require 'test_helper'

module Matcher
  describe BooleanMatcher do
    it 'is built by boolean' do
      matcher = Matcher.build { boolean }

      assert_kind_of BooleanMatcher, matcher
    end

    it 'matches true and false' do
      matcher = Matcher.build { boolean }
      negated = ~matcher

      assert matcher.match?(true)
      assert_no_errors matcher.match(true)
      refute negated.match?(true)
      assert_errors negated.match(true), msg(true).in([false, true])

      assert matcher.match?(false)
      assert_no_errors matcher.match(false)
      refute negated.match?(false)
      assert_errors negated.match(false), msg(false).in([false, true])

      refute matcher.match?(1)
      assert_errors matcher.match(1), msg(1).not.in([false, true])
      assert negated.match?(1)
      assert_no_errors negated.match(1)
    end

    it '#to_s' do
      matcher = Matcher.build { boolean }

      assert_equal 'boolean', matcher.to_s
      assert_equal '~boolean', matcher.~.to_s
    end
  end
end
