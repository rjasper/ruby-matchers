# frozen_string_literal: true

require 'test_helper'

describe Matcher::Hole do
  include Matcher::PatternTesting

  describe '#to_s' do
    it 'looks like method_hole(:key, :method)' do
      pattern = Matcher::Pattern.build do
        method_hole(:key, _, :apply)
      end

      hole = pattern.expression.value

      assert_kind_of Matcher::MethodHole, hole
      assert_equal 'method_hole(:key, actual, :apply)', hole.to_s
    end

    it 'looks like method_hole(:key, :method, arg, key: value)' do
      pattern = Matcher::Pattern.build do
        method_hole(:key, _, :apply, vars[:foo], bar: vars[:bar])
      end

      hole = pattern.expression.value

      assert_kind_of Matcher::MethodHole, hole
      assert_equal 'method_hole(:key, actual, :apply, foo, bar: bar)', hole.to_s
    end
  end

  it 'matches receiver and arguments' do
    with_pattern -> { method_hole(:call, _, :foo, const(:arg), mode: var(:kwarg)) } do
      assert_pattern_match _.foo(1, mode: vars[:opt]),
        call: _.foo(1, mode: vars[:opt]),
        arg: 1,
        kwarg: vars[:opt]

      assert_no_pattern_match parent.foo(1, mode: vars[:opt])
      assert_no_pattern_match _.foo(vars[:foo], mode: vars[:opt])
      assert_no_pattern_match _.foo(1, mode: 2)
    end
  end

  it 'matches method with array' do
    with_pattern -> { method_hole(:call, _, %i[foo bar]) } do
      assert_pattern_match _.foo, call: _.foo
      assert_pattern_match _.bar, call: _.bar

      assert_no_pattern_match _.baz
    end
  end

  it 'matches method with proc' do
    with_pattern -> { method_hole(:call, _, -> { _1.end_with?('!') }) } do
      assert_pattern_match _.foo!, call: _.foo!

      assert_no_pattern_match _.foo
    end
  end
end
