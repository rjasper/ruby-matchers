# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class HashMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match type' do
      matcher = HashMatcher.new({})

      assert_errors matcher.match(1), 'expected a Hash but got 1'
    end

    test 'match all entries' do
      matcher = HashMatcher.new({ foo: v('foo') }, all_entries: true)

      assert_predicate matcher.match({ foo: 'foo' }), :valid?
      assert_errors matcher.match({ foo: 'foo', bar: 'bar' }),
        bar: 'expected entry for :bar to not be present'
      assert_errors matcher.match({}),
        foo: 'expected entry for :foo but found nothing'
    end

    test 'match partial entries' do
      matcher = HashMatcher.new({ foo: v('foo') }, all_entries: false)

      assert_predicate matcher.match({ foo: 'foo' }), :valid?
      assert_predicate matcher.match({ foo: 'foo', bar: 'bar' }), :valid?
      assert_errors matcher.match({}),
        foo: 'expected entry for :foo but found nothing'
    end

    test 'match nested hash' do
      matcher = HashMatcher.new({ foo: h(bar: v('baz')) })

      assert_predicate matcher.match({ foo: { bar: 'baz' } }), :valid?
      assert_errors matcher.match({ foo: { bar: 'buzz' } }),
        foo: { bar: 'expected "baz" but got "buzz"' }
      assert_not_predicate matcher.match({ foo: 'foo' }), :valid?
    end

    test 'match nested matcher' do
      child = HashMatcher.new({ bar: v('foobar') })
      parent = HashMatcher.new({ foo: child })

      assert_predicate parent.match({ foo: { bar: 'foobar' } }), :valid?
    end
  end
end
