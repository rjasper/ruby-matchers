# frozen_string_literal: true

require 'test_helper'

describe Matcher::LetMatcher do
  it 'is build by let' do
    kind = Matcher::LetMatcher

    assert_kind_of(kind, Matcher.build { let({ n: 1 }, _ == vars[:n]) })
    assert_kind_of(kind, Matcher.build { let(n: 1) ^ (_ == vars[:n]) })
  end

  it '#match?' do
    matcher = Matcher.build { let(n: 1) ^ (_ == vars[:n]) }
    negated = ~matcher

    assert matcher.match?(1)
    refute negated.match?(1)

    refute matcher.match?(4)
    assert negated.match?(4)
  end

  it 'sets variable to value' do
    matcher = Matcher.build do
      let(myvar: 'foo') ^
        (_ == vars[:myvar])
    end

    negated = ~matcher

    assert_no_errors matcher.match('foo')
    assert_errors negated.match('foo'),
      'expected actual != myvar but got "foo" != "foo"'

    assert_errors matcher.match('bar'),
      'expected actual == myvar but got "bar" == "foo"'
    assert_no_errors negated.match('bar')
  end

  it 'sets variables via block' do
    matcher = Matcher.build do
      let(
        depth: 0,
        parent_value: ->(x) { x[:value] },
      ) ^ {
        depth: _ == vars[:depth],
        value: 42,
        child: let(depth: ->(depth:) { depth + 1 }) ^ {
          depth: _ == vars[:depth],
          value: _ == vars[:parent_value] / 2 + 2,
        },
      }
    end

    negated = ~matcher

    actual = {
      depth: 0,
      value: 42,
      child: {
        depth: 1,
        value: 23,
      },
    }

    assert_no_errors matcher.match(actual)
    assert_errors negated.match(actual) do
      _or do
        error :depth, 'expected actual != depth but got 0 != 0'
        error :value, msg(42).equal(42)
        error %i[child depth], 'expected actual != depth but got 1 != 1'
        error %i[child value], 'expected actual != parent_value / 2 + 2 but got 23 != 23, where parent_value = 42'
      end
    end

    actual = {
      depth: 0,
      value: 16,
      child: {
        depth: 2,
        value: 11,
      },
    }

    assert_errors matcher.match(actual),
      value: 'expected 42 but got 16',
      child: {
        depth: 'expected actual == depth but got 2 == 1',
        value: 'expected actual == parent_value / 2 + 2 but got 11 == 10, where parent_value = 16',
      }
    assert_no_errors negated.match(actual)
  end

  it 'sets variable to expression value' do
    matcher = Matcher.build do
      let(foo: _ * 2) ^ (vars[:foo] == 4)
    end

    assert_no_errors matcher.match(2)
    assert_errors matcher.match(3), 'expected foo == 4 but got 6 == 4'
  end

  it 'sets actual' do
    matcher = Matcher.build do
      each_pair ^ let(actual: ->(key:, value:) { key + value }) ^ of(_.even?)
    end

    assert_no_errors matcher.match({ 2 => 4, 1 => 3 })

    assert_errors matcher.match({ 1 => 2, 4 => 3 }),
      1 => msg(3).not.predicate(:even?),
      4 => msg(7).not.predicate(:even?)
  end

  it '#to_s' do
    t = self

    Matcher.build do
      declare :a, :b

      t.assert_equal 'let(a: 0, b: ->(x) { ... }) ^ (actual == a + b)',
        (let(a: 0, b: ->(x) { 2 * x }) ^ (_ == a + b)).to_s
      t.assert_equal 'let(a: 0, b: ->(x) { ... }) ^ (a + b).even?',
        (let(a: 0, b: ->(x) { 2 * x }) ^ (a + b).even?).to_s
      t.assert_equal 'let(a: 0, b: ->(x) { ... }) ^ [a, b]',
        (let(a: 0, b: ->(x) { 2 * x }) ^ [a, b]).to_s
      t.assert_equal "let(a: 0, b: ->(x) { ... }) ^ -> { let_matcher_spec.rb:#{__LINE__ + 1} }",
        (let(a: 0, b: ->(x) { 2 * x }) ^ -> { false }).to_s
      t.assert_equal "let(a: 0, b: ->(x) { ... }) ^ partial(#{{ foo: 42 }})",
        (let(a: 0, b: ->(x) { 2 * x }) ^ partial({ foo: 42 })).to_s

      t.assert_equal 'let(a: 0) ^ neg(actual > a)', neg(let(a: 0) ^ (_ > a)).to_s

      nil
    end
  end
end
