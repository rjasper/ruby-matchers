# frozen_string_literal: true

require 'test_helper'

describe Matcher::HashMatcher do
  it 'expects a Hash' do
    matcher = Matcher::HashMatcher.new({})

    assert_errors matcher.match(1), msg_not(:kind_of, 1, Hash)
    assert_expected_errors matcher.match(1), 'expected a kind of Hash but got 1'
  end

  it 'expects key to be included' do
    matcher = Matcher.build do
      { foo: 'foo' }
    end

    assert_errors matcher.match({}),
      foo: msg_not(:having_key, {}, :foo)
    assert_expected_errors matcher.match({}),
      foo: 'expected to include key :foo but got {}'
  end

  it 'match all entries' do
    matcher = Matcher::HashMatcher.new({ foo: v('foo') })

    assert_predicate matcher.match({ foo: 'foo' }), :valid?
    assert_expected_errors matcher.match({ foo: 'foo', bar: 'bar' }),
      bar: 'did not expect to include key :bar but got {:foo=>"foo", :bar=>"bar"}'
    assert_expected_errors matcher.match({}),
      foo: 'expected to include key :foo but got {}'
  end

  it 'match partial entries' do
    matcher = Matcher::HashMatcher.new({ foo: v('foo') }, partial: true)

    assert_predicate matcher.match({ foo: 'foo' }), :valid?
    assert_predicate matcher.match({ foo: 'foo', bar: 'bar' }), :valid?
    assert_expected_errors matcher.match({}),
      foo: 'expected to include key :foo but got {}'
  end

  it 'match nested hash' do
    matcher = Matcher::HashMatcher.new({ foo: h(bar: v('baz')) })

    assert_predicate matcher.match({ foo: { bar: 'baz' } }), :valid?
    assert_expected_errors matcher.match({ foo: { bar: 'buzz' } }),
      foo: { bar: 'expected "baz" but got "buzz"' }
    assert_expected_errors matcher.match({ foo: 'foo' }),
      foo: msg_not(:kind_of, 'foo', Hash)
  end

  it 'pass key' do
    matcher = Matcher.build do
      { a: _ == key.to_s.upcase }
    end

    assert_expected_errors matcher.match({ a: 'B' }),
      a: 'expected _ to be k.to_s.upcase ("A") but got "B" for k = :a'
  end

  it 'pass parent' do
    matcher = Matcher.build do
      { self: _ == parent }
    end

    self_hash = {}
    self_hash[:self] = self_hash

    assert_predicate matcher.match(self_hash), :valid?
    assert_expected_errors matcher.match({ self: {} }),
      self: 'expected _ to be parent ({:self=>{}}) but got {}'
  end

  it '#to_s: all entries' do
    matcher = Matcher::HashMatcher.new({ a: h(b: v('c')) })

    assert_equal '{:a=>{:b=>"c"}}', matcher.to_s
  end

  it '#to_s: partial entries' do
    matcher = Matcher::HashMatcher.new({ a: h(b: v('c')) }, partial: true)

    assert_equal 'partial({:a=>{:b=>"c"}})', matcher.to_s
  end
end
