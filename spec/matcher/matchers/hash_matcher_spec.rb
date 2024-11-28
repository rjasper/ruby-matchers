# frozen_string_literal: true

require 'test_helper'

describe Matcher::HashMatcher do
  it 'is built from Hash and by partial' do
    kind = Matcher::HashMatcher

    assert_kind_of(kind, Matcher.build { { foo: 'bar' } })
    assert_kind_of(kind, Matcher.build { partial({ foo: 'bar' }) })
    assert_kind_of(kind, Matcher.build { partial_r({ foo: 'bar' }) })
  end

  it 'builds partial hash matcher recursively with partial_r' do
    matcher = Matcher.build do
      partial_r({ a: { a1: 'a1' } })
    end

    assert_no_errors matcher.match({ a: { a1: 'a1', a2: 'a2' }, b: 'b' })
    assert_errors matcher.~.match({ a: { a1: 'a1', a2: 'a2' }, b: 'b' }),
      a: { a1: msg('a1').equal('a1') }
  end

  it 'expects a Hash' do
    matcher = Matcher.build { {} }

    assert_errors matcher.match(1),
      msg(1).not.kind_of(Hash)
    assert_no_errors matcher.~.match(1)
  end

  it 'expects key to be included' do
    matcher = Matcher.build { { foo: 'foo' } }
    negated = ~matcher

    assert_errors matcher.match({}),
      msg({}).not.having_key(:foo)
    assert_no_errors negated.match({})
  end

  it 'matches all entries' do
    matcher = Matcher.build { { foo: 'foo' } }
    negated = ~matcher

    assert_no_errors matcher.match({ foo: 'foo' })
    assert_errors negated.match({ foo: 'foo' }),
      foo: msg('foo').equal('foo')

    assert_errors matcher.match({ foo: 'foo', bar: 'bar' }),
      bar: msg({ foo: 'foo', bar: 'bar' }).having_key(:bar)
    assert_no_errors negated.match({ foo: 'foo', bar: 'bar' })

    assert_errors matcher.match({}),
      msg({}).not.having_key(:foo)
    assert_no_errors negated.match({})
  end

  it 'matches partial entries' do
    matcher = Matcher.build { partial({ foo: 'foo' }) }
    negated = ~matcher

    assert_no_errors matcher.match({ foo: 'foo' })
    assert_errors negated.match({ foo: 'foo' }),
      foo: msg('foo').equal('foo')

    assert_no_errors matcher.match({ foo: 'foo', bar: 'bar' })
    assert_errors negated.match({ foo: 'foo', bar: 'bar' }),
      foo: msg('foo').equal('foo')

    assert_errors matcher.match({}),
      msg({}).not.having_key(:foo)
    assert_no_errors negated.match({})
  end

  it 'matches a nested hashes' do
    matcher = Matcher.build { { foo: { bar: 'baz' } } }
    negated = ~matcher

    assert_no_errors matcher.match({ foo: { bar: 'baz' } })
    assert_errors negated.match({ foo: { bar: 'baz' } }),
      foo: { bar: msg('baz').equal('baz') }

    assert_errors matcher.match({ foo: { bar: 'buzz' } }),
      foo: { bar: msg('buzz').not.equal('baz') }
    assert_no_errors negated.match({ foo: { bar: 'buzz' } })

    assert_errors matcher.match({ foo: 'foo' }),
      foo: msg('foo').not.kind_of(Hash)
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
