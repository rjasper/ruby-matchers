# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::NegatedHashMatcher do
  it 'match not type' do
    matcher = Matcher::NegatedHashMatcher.new({})

    assert_predicate matcher.match(1), :valid?
  end

  it 'match not all entries' do
    matcher = ~Matcher.build do
      { foo: 'foo' }
    end

    assert_errors matcher.match({ foo: 'foo' }),
      foo: 'expected "foo" to not be "foo"'

    assert_predicate matcher.match({ foo: 'foo', bar: 'bar' }), :valid?
    assert_predicate matcher.match({}), :valid?
  end

  it 'match not partial entries' do
    matcher = Matcher.build do
      ~partial_entries({ foo: 'foo' })
    end

    assert_errors matcher.match({ foo: 'foo' }),
      foo: 'expected "foo" to not be "foo"'
    assert_errors matcher.match({ foo: 'foo', bar: 'bar' }),
      foo: 'expected "foo" to not be "foo"'

    assert_predicate matcher.match({}), :valid?
  end

  it 'match not nested hash' do
    matcher = Matcher.build do
      neg({ foo: { bar: 'baz' } })
    end

    assert_errors matcher.match({ foo: { bar: 'baz' } }),
      foo: { bar: 'expected "baz" to not be "baz"' }

    assert_predicate matcher.match({ foo: { bar: 'buzz' } }), :valid?
    assert_predicate matcher.match({ foo: 'foo' }), :valid?
  end

  it '#to_s: all entries' do
    matcher = Matcher.build { neg({ a: { b: 'c' } }) }

    assert_equal 'neg({:a=>{:b=>"c"}})', matcher.to_s
  end

  it '#to_s: partial entries'
end
