# frozen_string_literal: true

require 'test_helper'

describe Matcher::SetVariablesMatcher do
  it 'set variable to value' do
    matcher = Matcher.build do
      setvar({ myvar: 'foo' }, _ == vars[:myvar])
    end

    assert_no_errors matcher.match('foo')
    assert_expected_errors matcher.match('bar'),
      'expected _ == myvar but got "bar" == "foo"'

    negated = ~matcher

    assert_expected_errors negated.match('foo'), 'expected _ != myvar but got "foo" != "foo"'
    assert_no_errors negated.match('bar')
  end

  it 'set variables via block' do
    matcher = Matcher.build do
      setvar(
        {
          depth: 0,
          parent_value: ->(_) { _[:value] }
        },
        {
          depth: _ == vars[:depth],
          value: 42,
          child: setvar(
            { depth: ->(depth:) { depth + 1 } },
            {
              depth: _ == vars[:depth],
              value: _ == vars[:parent_value] / 2 + 2,
            },
          ),
        }
      )
    end

    actual = {
      depth: 0,
      value: 42,
      child: {
        depth: 1,
        value: 23,
      }
    }

    assert_no_errors matcher.match(actual)

    actual = {
      depth: 0,
      value: 16,
      child: {
        depth: 2,
        value: 11,
      }
    }

    assert_expected_errors matcher.match(actual),
      value: 'expected 42 but got 16',
      child: {
        depth: 'expected _ == depth but got 2 == 1',
        value: 'expected _ == parent_value / 2 + 2 but got 11 == 10, where parent_value = 16'
      }
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
      t.assert_equal "setvar(a: 0, b: ->(_) { ... }) ^ -> { set_variables_matcher_test.rb:#{__LINE__ + 1} }",
        (setvar(a: 0, b: ->(_) { 2 * _ }) ^ -> { false }).to_s
      t.assert_equal "setvar(a: 0, b: ->(_) { ... }) ^ partial({:foo=>42})",
        (setvar(a: 0, b: ->(_) { 2 * _ }) ^ partial({ foo: 42 })).to_s

      nil
    end
  end
end
