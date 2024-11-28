# frozen_string_literal: true

require 'test_helper'

describe Matcher::SetVariablesMatcher do
  it 'is build by setvar' do
    kind = Matcher::SetVariablesMatcher

    assert_kind_of(kind, Matcher.build { setvar({ n: 1 }, _ == vars[:n]) })
    assert_kind_of(kind, Matcher.build { setvar(n: 1) ^ (_ == vars[:n]) })
  end

  it 'sets variable to value' do
    matcher = Matcher.build do
      setvar(myvar: 'foo') ^
        (_ == vars[:myvar])
    end

    negated = ~matcher

    assert_no_errors matcher.match('foo')
    assert_errors negated.match('foo'),
      'expected _ != myvar but got "foo" != "foo"'

    assert_errors matcher.match('bar'),
      'expected _ == myvar but got "bar" == "foo"'
    assert_no_errors negated.match('bar')
  end

  it 'sets variables via block' do
    matcher = Matcher.build do
      setvar(
        depth: 0,
        parent_value: ->(_) { _[:value] },
      ) ^ {
        depth: _ == vars[:depth],
        value: 42,
        child: setvar(depth: ->(depth:) { depth + 1 }) ^ {
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
        error :depth, 'expected _ != depth but got 0 != 0'
        error :value, msg(42).equal(42)
        error %i[child depth], 'expected _ != depth but got 1 != 1'
        error %i[child value], 'expected _ != parent_value / 2 + 2 but got 23 != 23, where parent_value = 42'
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
        depth: 'expected _ == depth but got 2 == 1',
        value: 'expected _ == parent_value / 2 + 2 but got 11 == 10, where parent_value = 16',
      }
    assert_no_errors negated.match(actual)
  end

  it '#to_s' do
    t = self

    Matcher.build do
      declare :a, :b

      t.assert_equal 'setvar(a: 0, b: ->(_) { ... }) ^ (_ == a + b)',
        (setvar(a: 0, b: ->(_) { 2 * _ }) ^ (_ == a + b)).to_s
      t.assert_equal 'setvar(a: 0, b: ->(_) { ... }) ^ (a + b).even?',
        (setvar(a: 0, b: ->(_) { 2 * _ }) ^ (a + b).even?).to_s
      t.assert_equal 'setvar(a: 0, b: ->(_) { ... }) ^ [a, b]',
        (setvar(a: 0, b: ->(_) { 2 * _ }) ^ [a, b]).to_s
      t.assert_equal "setvar(a: 0, b: ->(_) { ... }) ^ -> { set_variables_matcher_spec.rb:#{__LINE__ + 1} }",
        (setvar(a: 0, b: ->(_) { 2 * _ }) ^ -> { false }).to_s
      t.assert_equal "setvar(a: 0, b: ->(_) { ... }) ^ partial({:foo=>42})",
        (setvar(a: 0, b: ->(_) { 2 * _ }) ^ partial({ foo: 42 })).to_s

      t.assert_equal 'setvar(a: 0) ^ neg(_ > a)', neg(setvar(a: 0) ^ (_ > a)).to_s

      nil
    end
  end
end
