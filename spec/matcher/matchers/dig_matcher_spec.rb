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

    assert matcher.match?({ foo: ['foobar'] })
    assert_no_errors matcher.match({ foo: ['foobar'] })
    refute negated.match?({ foo: ['foobar'] })
    assert_errors negated.match({ foo: ['foobar'] }),
      foo: { 0 => msg('foobar').equal('foobar') }

    refute matcher.match?({ foo: [] })
    assert_errors matcher.match({ foo: [] }),
      foo: msg([]).not.having_index(0)
    assert negated.match?({ foo: [] })
    assert_no_errors negated.match({ foo: [] })

    refute matcher.match?({})
    assert_errors matcher.match({}),
      msg({}).not.having_key(:foo)
    assert negated.match?({})
    assert_no_errors negated.match({})

    refute matcher.match?({ foo: 'bar' })
    assert_errors matcher.match({ foo: 'bar' }) do
      _or(:foo) do
        error msg('bar').not.kind_of(Hash)
        error msg('bar').not.kind_of(Array)
      end
    end
    assert negated.match?({ foo: 'bar' })
    assert_no_errors negated.match({ foo: 'bar' })

    refute matcher.match?({ foo: [nil] })
    assert_errors matcher.match({ foo: [nil] }),
      foo: { 0 => msg(nil).not.equal('foobar') }
    assert negated.match?({ foo: [nil] })
    assert_no_errors negated.match({ foo: [nil] })

    refute matcher.match?({ foo: ['qux'] })
    assert_errors matcher.match({ foo: ['qux'] }),
      foo: { 0 => msg('qux').not.equal('foobar') }
    assert negated.match?({ foo: ['qux'] })
    assert_no_errors negated.match({ foo: ['qux'] })

    refute matcher.match?([])
    assert_errors matcher.match([]),
      msg([]).not.kind_of(Hash)
    assert negated.match?([])
    assert_no_errors negated.match([])
  end

  it 'matches digged value optionally' do
    matcher = Matcher.build do
      optional_dig(:foo, 0) ^ 'foobar'
    end

    negated = ~matcher

    assert matcher.match?({ foo: ['foobar'] })
    assert_no_errors matcher.match({ foo: ['foobar'] })
    refute negated.match?({ foo: ['foobar'] })
    assert_errors negated.match({ foo: ['foobar'] }),
      foo: { 0 => msg('foobar').equal('foobar') }

    assert matcher.match?({ foo: [] })
    assert_no_errors matcher.match({ foo: [] })
    refute negated.match?({ foo: [] })
    assert_errors negated.match({ foo: [] }),
      foo: msg([]).not.having_index(0)

    assert matcher.match?({})
    assert_no_errors matcher.match({})
    refute negated.match?({})
    assert_errors negated.match({}),
      msg({}).not.having_key(:foo)

    refute matcher.match?({ foo: 'bar' })
    assert_errors matcher.match({ foo: 'bar' }) do
      _or(:foo) do
        error msg('bar').not.kind_of(Hash)
        error msg('bar').not.kind_of(Array)
      end
    end
    assert negated.match?({ foo: 'bar' })
    assert_no_errors negated.match({ foo: 'bar' })

    refute matcher.match?({ foo: nil })
    assert_errors matcher.match({ foo: nil }) do
      _or(:foo) do
        error msg(nil).not.kind_of(Hash)
        error msg(nil).not.kind_of(Array)
      end
    end
    assert negated.match?({ foo: nil })
    assert_no_errors negated.match({ foo: nil })

    refute matcher.match?({ foo: [nil] })
    assert_errors matcher.match({ foo: [nil] }),
      foo: { 0 => msg(nil).not.equal('foobar') }
    assert negated.match?({ foo: [nil] })
    assert_no_errors negated.match({ foo: [nil] })

    refute matcher.match?({ foo: ['qux'] })
    assert_errors matcher.match({ foo: ['qux'] }),
      foo: { 0 => msg('qux').not.equal('foobar') }
    assert negated.match?({ foo: ['qux'] })
    assert_no_errors negated.match({ foo: ['qux'] })

    refute matcher.match?([])
    assert_errors matcher.match([]),
      msg([]).not.kind_of(Hash)
    assert negated.match?([])
    assert_no_errors negated.match([])
  end

  it 'evaluates expression keys' do
    matcher = Matcher.build do
      declare foo: 'foo'
      dig(foo) ^ 42
    end

    assert_no_errors matcher.match({ 'foo' => 42 })
  end

  it '#to_s' do
    assert_equal('dig(:foo, 0) ^ "foo"', Matcher.build { dig(:foo, 0) ^ 'foo' }.to_s)
    assert_equal('~dig(:foo, 0) ^ "foo"', Matcher.build { ~dig(:foo, 0) ^ 'foo' }.to_s)
    assert_equal('optional_dig(:foo, 0) ^ "foo"', Matcher.build { optional_dig(:foo, 0) ^ 'foo' }.to_s)
    assert_equal('~optional_dig(:foo, 0) ^ "foo"', Matcher.build { ~optional_dig(:foo, 0) ^ 'foo' }.to_s)
  end
end
