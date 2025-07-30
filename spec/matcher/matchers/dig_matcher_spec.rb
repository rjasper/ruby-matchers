# frozen_string_literal: true

require 'test_helper'

describe Matcher::DigMatcher do
  it 'is built by dig' do
    matcher = Matcher.build { dig(:foo, :bar) ^ 'foobar' }

    assert_kind_of(Matcher::DigMatcher, matcher)

    matcher = Matcher.build { optional_dig(:foo, :bar) ^ 'foobar' }

    assert_kind_of(Matcher::DigMatcher, matcher)
  end

  it 'matches digged value' do
    matcher = Matcher.build do
      dig(:foo, 0) ^ 'foobar'
    end

    negated = ~matcher

    assert_no_errors matcher.match({ foo: ['foobar'] })
    assert_errors negated.match({ foo: ['foobar'] }),
      foo: { 0 => msg('foobar').equal('foobar') }

    assert_errors matcher.match({ foo: [] }),
      foo: msg([]).not.having_index(0)
    assert_no_errors negated.match({ foo: [] })

    assert_errors matcher.match({}),
      msg({}).not.having_key(:foo)
    assert_no_errors negated.match({})

    assert_errors matcher.match({ foo: 'bar' }) do
      _or(:foo) do
        error msg('bar').not.kind_of(Hash)
        error msg('bar').not.kind_of(Array)
      end
    end
    assert_no_errors negated.match({ foo: 'bar' })

    assert_errors matcher.match({ foo: [nil] }),
      foo: { 0 => msg(nil).not.equal('foobar') }
    assert_no_errors negated.match({ foo: [nil] })

    assert_errors matcher.match({ foo: ['qux'] }),
      foo: { 0 => msg('qux').not.equal('foobar') }
    assert_no_errors negated.match({ foo: ['qux'] })

    assert_errors matcher.match([]),
      msg([]).not.kind_of(Hash)
    assert_no_errors negated.match([])
  end

  it 'matches digged value optionally' do
    matcher = Matcher.build do
      optional_dig(:foo, 0) ^ 'foobar'
    end

    negated = ~matcher

    assert_no_errors matcher.match({ foo: ['foobar'] })
    assert_errors negated.match({ foo: ['foobar'] }),
      foo: { 0 => msg('foobar').equal('foobar') }

    assert_no_errors matcher.match({ foo: [] })
    assert_errors negated.match({ foo: [] }),
      foo: msg([]).not.having_index(0)

    assert_no_errors matcher.match({})
    assert_errors negated.match({}),
      msg({}).not.having_key(:foo)

    assert_errors matcher.match({ foo: 'bar' }) do
      _or(:foo) do
        error msg('bar').not.kind_of(Hash)
        error msg('bar').not.kind_of(Array)
      end
    end
    assert_no_errors negated.match({ foo: 'bar' })

    assert_no_errors matcher.match({ foo: [nil] })
    assert_errors negated.match({ foo: [nil] }),
      foo: { 0 => msg(nil).equal(nil) }

    assert_errors matcher.match({ foo: ['qux'] }),
      foo: { 0 => msg('qux').not.equal('foobar') }
    assert_no_errors negated.match({ foo: ['qux'] })

    assert_errors matcher.match([]),
      msg([]).not.kind_of(Hash)
    assert_no_errors negated.match([])
  end

  it '#to_s' do
    assert_equal('dig(:foo, 0) ^ "foo"', Matcher.build { dig(:foo, 0) ^ 'foo' }.to_s)
    assert_equal('~dig(:foo, 0) ^ "foo"', Matcher.build { ~dig(:foo, 0) ^ 'foo' }.to_s)
    assert_equal('optional_dig(:foo, 0) ^ "foo"', Matcher.build { optional_dig(:foo, 0) ^ 'foo' }.to_s)
    assert_equal('~optional_dig(:foo, 0) ^ "foo"', Matcher.build { ~optional_dig(:foo, 0) ^ 'foo' }.to_s)
  end
end
