# frozen_string_literal: true

require 'test_helper'

describe Matcher::HashMatcher do
  it 'is built from Hash and by partial' do
    kind = Matcher::HashMatcher

    assert_kind_of(kind, Matcher.build { { foo: 'bar' } })
    assert_kind_of(kind, Matcher.build { partial({ foo: 'bar' }) })
    assert_kind_of(kind, Matcher.build { partial_r({ foo: 'bar' }) })
  end

  describe 'raises on illegal keys' do
    it 'raises on matcher key' do
      e = assert_raises StandardError do
        Matcher.build { { of('foo') => 'bar' } }
      end

      assert_equal 'Cannot use matcher as key for hash matcher', e.message
    end

    it 'raises on pipe key' do
      e = assert_raises StandardError do
        Matcher.build { { dig(:foo, :bar) => 'foobar' } }
      end

      assert_equal 'Cannot use Matcher::Pipe as key for hash matcher', e.message
    end

    it 'raises on vars key' do
      e = assert_raises StandardError do
        Matcher.build { { vars => 'foobar' } }
      end

      expected = 'Cannot use Matcher::ExpressionBuilding::VariableFactory as key for hash matcher'

      assert_equal expected, e.message
    end

    it 'raises on refs key' do
      e = assert_raises StandardError do
        Matcher.build { { refs => 'foobar' } }
      end

      expected = 'Cannot use Matcher::ReferenceMatcherCollection as key for hash matcher'

      assert_equal expected, e.message
    end
  end

  it 'builds partial hash matcher recursively with partial_r' do
    matcher = Matcher.build { partial_r({ a: { a1: 'a1' } }) }
    negated = ~matcher

    assert matcher.match?({ a: { a1: 'a1', a2: 'a2' }, b: 'b' })
    assert_no_errors matcher.match({ a: { a1: 'a1', a2: 'a2' }, b: 'b' })

    refute negated.match?({ a: { a1: 'a1', a2: 'a2' }, b: 'b' })
    assert_errors negated.match({ a: { a1: 'a1', a2: 'a2' }, b: 'b' }),
      a: { a1: msg('a1').equal('a1') }
  end

  it 'expects a Hash' do
    matcher = Matcher.build { {} }

    refute matcher.match?(1)
    assert_errors matcher.match(1),
      msg(1).not.kind_of(Hash)

    assert matcher.~.match?(1)
    assert_no_errors matcher.~.match(1)
  end

  it 'expects key to be included' do
    matcher = Matcher.build { { foo: 'foo' } }
    negated = ~matcher

    refute matcher.match?({})
    assert_errors matcher.match({}),
      msg({}).not.having_key(:foo)

    assert negated.match?({})
    assert_no_errors negated.match({})
  end

  it 'matches all entries' do
    matcher = Matcher.build { { foo: 'foo' } }
    negated = ~matcher

    assert matcher.match?({ foo: 'foo' })
    assert_no_errors matcher.match({ foo: 'foo' })

    refute negated.match?({ foo: 'foo' })
    assert_errors negated.match({ foo: 'foo' }),
      foo: msg('foo').equal('foo')

    refute matcher.match?({ foo: 'foo', bar: 'bar' })
    assert_errors matcher.match({ foo: 'foo', bar: 'bar' }),
      bar: msg({ foo: 'foo', bar: 'bar' }).having_key(:bar)

    assert negated.match?({ foo: 'foo', bar: 'bar' })
    assert_no_errors negated.match({ foo: 'foo', bar: 'bar' })

    refute matcher.match?({})
    assert_errors matcher.match({}),
      msg({}).not.having_key(:foo)

    assert negated.match?({})
    assert_no_errors negated.match({})
  end

  it 'matches multiple entries' do
    matcher = Matcher.build { { foo: 'foo', bar: 'bar' } }
    negated = ~matcher

    assert matcher.match?({ foo: 'foo', bar: 'bar' })
    assert_no_errors matcher.match({ foo: 'foo', bar: 'bar' })

    refute negated.match?({ foo: 'foo', bar: 'bar' })
    assert_or_errors negated.match({ foo: 'foo', bar: 'bar' }),
      foo: msg('foo').equal('foo'),
      bar: msg('bar').equal('bar')
  end

  it 'matches partial entries' do
    matcher = Matcher.build { partial({ foo: 'foo' }) }
    negated = ~matcher

    assert matcher.match?({ foo: 'foo' })
    assert_no_errors matcher.match({ foo: 'foo' })

    refute negated.match?({ foo: 'foo' })
    assert_errors negated.match({ foo: 'foo' }),
      foo: msg('foo').equal('foo')

    assert matcher.match?({ foo: 'foo', bar: 'bar' })
    assert_no_errors matcher.match({ foo: 'foo', bar: 'bar' })

    refute negated.match?({ foo: 'foo', bar: 'bar' })
    assert_errors negated.match({ foo: 'foo', bar: 'bar' }),
      foo: msg('foo').equal('foo')

    refute matcher.match?({})
    assert_errors matcher.match({}),
      msg({}).not.having_key(:foo)

    assert negated.match?({})
    assert_no_errors negated.match({})
  end

  it 'matches an empty hash' do
    matcher = Matcher.build { {} }
    negated = ~matcher

    assert matcher.match?({})
    assert_no_errors matcher.match({})

    refute negated.match?({})
    assert_errors negated.match({}),
      msg({}).predicate(:empty?)
  end

  it 'matches partially all hashes with empty hash' do
    matcher = Matcher::HashMatcher.new({}, partial: true)
    negated = ~matcher

    assert matcher.match?({})
    assert_no_errors matcher.match({})

    refute negated.match?({})
    assert_errors negated.match({}), msg({}).kind_of(Hash)
  end

  it 'matches a nested hashes' do
    matcher = Matcher.build { { foo: { bar: 'baz' } } }
    negated = ~matcher

    assert matcher.match?({ foo: { bar: 'baz' } })
    assert_no_errors matcher.match({ foo: { bar: 'baz' } })

    refute negated.match?({ foo: { bar: 'baz' } })
    assert_errors negated.match({ foo: { bar: 'baz' } }),
      foo: { bar: msg('baz').equal('baz') }

    refute matcher.match?({ foo: { bar: 'buzz' } })
    assert_errors matcher.match({ foo: { bar: 'buzz' } }),
      foo: { bar: msg('buzz').not.equal('baz') }

    assert negated.match?({ foo: { bar: 'buzz' } })
    assert_no_errors negated.match({ foo: { bar: 'buzz' } })

    refute matcher.match?({ foo: 'foo' })
    assert_errors matcher.match({ foo: 'foo' }),
      foo: msg('foo').not.kind_of(Hash)

    assert negated.match?({ foo: 'foo' })
    assert_no_errors negated.match({ foo: 'foo' })
  end

  it 'matches other entries' do
    matcher = Matcher.build do
      {
        foo: String,
        others => project(_.keys => each(Symbol)),
      }
    end

    negated = ~matcher
    t = self

    assert matcher.match?({ foo: 'foo', bar: 'bar', qux: 'qux' })
    assert_no_errors matcher.match({ foo: 'foo', bar: 'bar', qux: 'qux' })

    refute negated.match?({ foo: 'foo', bar: 'bar', qux: 'qux' })
    assert_errors negated.match({ foo: 'foo', bar: 'bar', qux: 'qux' }) do
      _or do
        error :foo, msg('foo').kind_of(String)
        error t.expression { _.keys[0] }, msg(:bar).kind_of(Symbol)
        error t.expression { _.keys[1] }, msg(:qux).kind_of(Symbol)
      end
    end

    refute matcher.match?({ foo: 'foo', 'bar' => :bar, qux: 'qux' })
    assert_errors matcher.match({ foo: 'foo', 'bar' => :bar, qux: 'qux' }),
      expression { _.keys[0] } => msg('bar').not.kind_of(Symbol)

    assert negated.match?({ foo: 'foo', 'bar' => :bar, qux: 'qux' })
    assert_no_errors negated.match({ foo: 'foo', 'bar' => :bar, qux: 'qux' })
  end

  it 'matches optional entries' do
    matcher = Matcher.build do
      { optional(:foo) => 'foo' }
    end

    negated = ~matcher

    assert matcher.match?({ foo: 'foo' })
    assert_no_errors matcher.match({ foo: 'foo' })

    refute negated.match?({ foo: 'foo' })
    assert_errors negated.match({ foo: 'foo' }),
      foo: msg('foo').equal('foo')

    assert matcher.match?({})
    assert_no_errors matcher.match({})

    refute negated.match?({})
    assert_errors negated.match({}),
      msg({}).predicate(:empty?)

    refute matcher.match?({ foo: 'bar' })
    assert_errors matcher.match({ foo: 'bar' }),
      foo: msg('bar').not.equal('foo')

    assert negated.match?({ foo: 'bar' })
    assert_no_errors negated.match({ foo: 'bar' })
  end

  it 'matches key expressions' do
    matcher = Matcher.build do
      declare :meta

      { meta[:key] => _ == meta[:value] }
    end

    negated = ~matcher
    meta = { key: :foo, value: 42 }

    assert matcher.match?({ foo: 42 }, meta:)
    assert_no_errors matcher.match({ foo: 42 }, meta:)

    refute negated.match?({ foo: 42 }, meta:)
    assert_errors negated.match({ foo: 42 }, meta:),
      expression { _[vars[:meta][:key]] } =>
          'expected _ != meta[:value] but got 42 != 42, where meta = {:key=>:foo, :value=>42}'

    refute matcher.match?({ foo: 43, bar: 23 }, meta:)
    assert_errors matcher.match({ foo: 43, bar: 23 }, meta:),
      bar: msg({ foo: 43, bar: 23 }).having_key(:bar),
      expression { _[vars[:meta][:key]] } =>
        'expected _ == meta[:value] but got 43 == 42, where meta = {:key=>:foo, :value=>42}'

    assert negated.match?({ foo: 43, bar: 23 }, meta:)
    assert_no_errors negated.match({ foo: 43, bar: 23 }, meta:)
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
