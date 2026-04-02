# frozen_string_literal: true

require "test_helper"

describe Matcher::KeysMatcher do
  it "is built by keys" do
    assert_kind_of(Matcher::KeysMatcher, Matcher.build { keys(:foo, :bar) })
    assert_kind_of(Matcher::KeysMatcher, Matcher.build { partial_keys(:foo, :bar) })
  end

  it "matches all keys" do
    matcher = Matcher.build { keys(:foo, :bar) }
    negated = ~matcher

    assert matcher.match?({ foo: 1, bar: 2 })
    assert_no_errors matcher.match({ foo: 1, bar: 2 })
    refute negated.match?({ foo: 1, bar: 2 })
    assert_or_errors negated.match({ foo: 1, bar: 2 }),
      msg({ foo: 1, bar: 2 }).having_key(:foo),
      msg({ foo: 1, bar: 2 }).having_key(:bar)

    refute matcher.match?({ foo: 1, qux: 3 })
    assert_errors matcher.match({ foo: 1, qux: 3 }),
      msg({ foo: 1, qux: 3 }).not.having_key(:bar),
      msg({ foo: 1, qux: 3 }).having_key(:qux)
    assert negated.match?({ foo: 1 })
    assert_no_errors negated.match({ foo: 1 })
    assert negated.match?({ foo: 1, bar: 2, qux: 3 })
    assert_no_errors negated.match({ foo: 1, bar: 2, qux: 3 })
    assert negated.match?({ foo: 1, qux: 3 })
    assert_no_errors negated.match({ foo: 1, qux: 3 })
  end

  it "matches partial keys" do
    matcher = Matcher.build { partial_keys(:foo, :bar) }
    negated = ~matcher

    assert matcher.match?({ foo: 1, bar: 2 })
    assert_no_errors matcher.match({ foo: 1, bar: 2 })
    refute negated.match?({ foo: 1, bar: 2 })
    assert_or_errors negated.match({ foo: 1, bar: 2 }),
      msg({ foo: 1, bar: 2 }).having_key(:foo),
      msg({ foo: 1, bar: 2 }).having_key(:bar)

    assert matcher.match?({ foo: 1, bar: 2, qux: 3 })
    assert_no_errors matcher.match({ foo: 1, bar: 2, qux: 3 })
    refute negated.match?({ foo: 1, bar: 2, qux: 3 })
    assert_or_errors negated.match({ foo: 1, bar: 2, qux: 3 }),
      msg({ foo: 1, bar: 2, qux: 3 }).having_key(:foo),
      msg({ foo: 1, bar: 2, qux: 3 }).having_key(:bar)

    refute matcher.match?({ foo: 1, qux: 3 })
    assert_errors matcher.match({ foo: 1, qux: 3 }),
      msg({ foo: 1, qux: 3 }).not.having_key(:bar)
    assert negated.match?({ foo: 1, qux: 3 })
    assert_no_errors negated.match({ foo: 1, qux: 3 })

    refute matcher.match?({ foo: 1 })
    assert_errors matcher.match({ foo: 1 }),
      msg({ foo: 1 }).not.having_key(:bar)
    assert negated.match?({ foo: 1 })
    assert_no_errors negated.match({ foo: 1 })
  end

  it "#to_s" do
    assert_equal "keys(:foo, :bar)", Matcher.build { keys(:foo, :bar) }.to_s
    assert_equal "partial_keys(:foo, :bar)", Matcher.build { partial_keys(:foo, :bar) }.to_s
  end
end
