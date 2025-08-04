# frozen_string_literal: true

require 'test_helper'

describe Matcher::EqualMatcher do
  it 'is built by equal and from objects' do
    assert_kind_of(Matcher::EqualMatcher, Matcher.build { equal(String) })
    assert_kind_of(Matcher::EqualMatcher, Matcher.build { 1 })
  end

  it 'matches value' do
    matcher = Matcher.build { 42 }
    negated = ~matcher

    assert_no_errors matcher.match(42)
    assert_errors negated.match(42),
      msg(42).equal(42)

    assert_errors matcher.match(23),
      msg(23).not.equal(42)
    assert_no_errors negated.match(23)
  end

  it 'matches expression' do
    matcher = Matcher.build do
      let(foo: 3) ^ equal(vars[:foo] * 14)
    end

    negated = ~matcher

    assert_no_errors matcher.match(42)
    assert_errors negated.match(42),
      msg(42).equal(42)

    assert_errors matcher.match(23),
      msg(23).not.equal(42)
    assert_no_errors negated.match(23)
  end

  it 'matches array' do
    matcher = Matcher.build { let(foo: 3) ^ equal([1, 2, vars[:foo]]) }
    negated = ~matcher

    assert_no_errors matcher.match([1, 2, 3])
    assert_or_errors negated.match([1, 2, 3]),
      0 => msg(1).equal(1),
      1 => msg(2).equal(2),
      2 => msg(3).equal(3)

    assert_errors matcher.match(1),
      msg(1).not.kind_of(Array)
    assert_no_errors negated.match(1)

    assert_errors matcher.match([1, 2]),
      msg([1, 2]).not.length_of(3, 2)
    assert_no_errors negated.match([1, 2])

    assert_errors matcher.match([1, 2, 4]),
      2 => msg(4).not.equal(3)
    assert_no_errors negated.match([1, 2, 4])
  end

  it 'matches hash' do
    matcher = Matcher.build { let(foo: 'foo') ^ equal({ foo: vars[:foo], bar: 'bar' }) }
    negated = ~matcher

    assert_no_errors matcher.match({ foo: 'foo', bar: 'bar' })
    assert_or_errors negated.match({ foo: 'foo', bar: 'bar' }),
      foo: msg('foo').equal('foo'),
      bar: msg('bar').equal('bar')

    assert_errors matcher.match(1),
      msg(1).not.kind_of(Hash)
    assert_no_errors negated.match(1)

    assert_errors matcher.match({ foo: 'foo' }),
      msg({ foo: 'foo' }).not.having_key(:bar)
    assert_no_errors negated.match({ foo: 'foo' })

    assert_errors matcher.match({ foo: 'foo', bar: 'baz' }),
      bar: msg('baz').not.equal('bar')
    assert_no_errors negated.match({ foo: 'foo', bar: 'baz' })
  end

  it '#to_s' do
    matcher = Matcher::EqualMatcher.new(1)

    assert_equal '1', matcher.to_s
    assert_equal 'neg(1)', matcher.~.to_s

    matcher = Matcher::EqualMatcher.new(1..10)

    assert_equal 'equal(1..10)', matcher.to_s
    assert_equal '~equal(1..10)', matcher.~.to_s
  end
end
