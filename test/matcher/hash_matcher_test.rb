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

    test 'pass key' do
      matcher = Matcher.build do
        { a: _ == key.to_s.upcase }
      end

      assert_errors matcher.match({ a: 'B' }),
        a: 'expected actual to be key.to_s.upcase ("A") but got "B" for key = :a'
    end

    test 'pass parent' do
      matcher = Matcher.build do
        { self: _ == parent }
      end

      self_hash = {}
      self_hash[:self] = self_hash

      assert_predicate matcher.match(self_hash), :valid?
      assert_errors matcher.match({ self: {} }),
        self: 'expected actual to be parent but got {}'
    end

    test '#inspect: all entries' do
      matcher = HashMatcher.new({ a: h(b: v('c')) })

      assert_equal '{:a=>{:b=>"c"}}', matcher.inspect
    end

    test '#inspect: partial entries' do
      matcher = HashMatcher.new({ a: h(b: v('c')) }, all_entries: false)

      assert_equal 'partial_entries({:a=>{:b=>"c"}})', matcher.inspect
    end
  end
end
