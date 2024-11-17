# frozen_string_literal: true

require 'test_helper'

describe Matcher::HashMatcher do
  it 'is built from Hash and by partial' do
    kind = Matcher::HashMatcher

    assert_kind_of(kind, Matcher.build { { foo: 'bar' } })
    assert_kind_of(kind, Matcher.build { partial({ foo: 'bar' }) })
    assert_kind_of(kind, Matcher.build { partial_r({ foo: 'bar' }) })
  end

  it 'expects a Hash' do
    matcher = Matcher.build { {} }

    assert_errors matcher.match(1),
      'expected a kind of Hash but got 1'
    assert_no_errors matcher.~.match(1)
  end

  it 'expects key to be included' do
    matcher = Matcher.build { { foo: 'foo' } }
    negated = ~matcher

    assert_errors matcher.match({}),
      'expected to include key :foo but got {}'
    assert_no_errors negated.match({})
  end

  it 'matches all entries' do
    matcher = Matcher.build { { foo: 'foo' } }
    negated = ~matcher

    assert_no_errors matcher.match({ foo: 'foo' })
    assert_errors negated.match({ foo: 'foo' }),
      foo: 'did not expect "foo"'

    assert_errors matcher.match({ foo: 'foo', bar: 'bar' }),
      bar: 'did not expect to include key :bar but got {:foo=>"foo", :bar=>"bar"}'
    assert_no_errors negated.match({ foo: 'foo', bar: 'bar' })

    assert_errors matcher.match({}),
      'expected to include key :foo but got {}'
    assert_no_errors negated.match({})
  end

  it 'matches partial entries' do
    matcher = Matcher.build { partial({ foo: 'foo' }) }
    negated = ~matcher

    assert_no_errors matcher.match({ foo: 'foo' })
    assert_errors negated.match({ foo: 'foo' }),
      foo: 'did not expect "foo"'

    assert_no_errors matcher.match({ foo: 'foo', bar: 'bar' })
    assert_errors negated.match({ foo: 'foo', bar: 'bar' }),
      foo: 'did not expect "foo"'

    assert_errors matcher.match({}),
      'expected to include key :foo but got {}'
    assert_no_errors negated.match({})
  end

  it 'matches a nested hashes' do
    matcher = Matcher.build { { foo: { bar: 'baz' } } }
    negated = ~matcher

    assert_no_errors matcher.match({ foo: { bar: 'baz' } })
    assert_errors negated.match({ foo: { bar: 'baz' } }),
      foo: { bar: 'did not expect "baz"' }

    assert_errors matcher.match({ foo: { bar: 'buzz' } }),
      foo: { bar: 'expected "baz" but got "buzz"' }
    assert_no_errors negated.match({ foo: { bar: 'buzz' } })

    assert_errors matcher.match({ foo: 'foo' }),
      foo: 'expected a kind of Hash but got "foo"'
    assert_no_errors negated.match({ foo: 'foo' })
  end

  it 'passes key' do
    matcher = Matcher.build do
      { a: _ == key.to_s.upcase }
    end

    assert_errors matcher.match({ a: 'B' }),
      a: 'expected _ == k.to_s.upcase but got "B" == "A", where k = :a'
  end

  it 'passes parent' do
    matcher = Matcher.build do
      { self: _ == parent }
    end

    self_hash = {}
    self_hash[:self] = self_hash

    assert_no_errors matcher.match(self_hash)
    assert_errors matcher.match({ self: {} }),
      self: 'expected _ == parent but got {} == {:self=>{}}'
  end

  it '#to_s: all entries' do
    matcher = Matcher.build { { a: { b: 'c' } } }

    assert_equal '{:a=>{:b=>"c"}}', matcher.to_s
    assert_equal 'neg({:a=>{:b=>"c"}})', matcher.~.to_s
  end

  it '#to_s: partial entries' do
    matcher = Matcher.build { partial({ a: { b: 'c' } }) }

    assert_equal 'partial({:a=>{:b=>"c"}})', matcher.to_s
    assert_equal '~partial({:a=>{:b=>"c"}})', matcher.~.to_s
  end
end
