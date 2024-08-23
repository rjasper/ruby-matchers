# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class SetVariablesMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'set variable to value' do
      matcher = Matcher.build do
        setvar({ myvar: 'foo' }, _ == vars[:myvar])
      end

      assert_predicate matcher.match('foo'), :valid?
      assert_errors matcher.match('bar'),
        'expected _ to be myvar ("foo") but got "bar"'
    end

    test 'set variables via block' do
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

      assert_predicate matcher.match(actual), :valid?

      actual = {
        depth: 0,
        value: 16,
        child: {
          depth: 2,
          value: 11,
        }
      }

      assert_errors matcher.match(actual),
        value: 'expected 42 but got 16',
        child: {
          depth: 'expected actual to be depth (1) but got 2',
          value: 'expected actual to be parent_value / 2 + 2 (10) but got 11 for parent_value = 16'
        }
    end

    test '#inspect' do
      matcher = Matcher.build do
        declare :a, :b

        setvar(a: 0, b: ->(_) { 2 * _ }) ^ (_ == a + b)
      end

      assert_equal 'setvar(a: 0, b: ->(_) { ... }) ^ (_ == a + b)', matcher.inspect
    end
  end
end
