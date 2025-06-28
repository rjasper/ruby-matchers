# frozen_string_literal: true

require 'test_helper'

describe Matcher::ProcExpression do
  it 'prohibits more than one arg' do
    err = assert_raises StandardError do
      build { |a, b| a + b }
    end

    assert_equal 'ProcExpression cannot have more than 1 arg', err.message
  end

  it 'prohibits actual kwarg' do
    err = assert_raises StandardError do
      build { |actual:| actual + 1 }
    end

    assert_equal 'ProcExpression cannot have an kwarg called "actual"', err.message
  end

  it '#variables' do
    expr = build { |_, x:| _ == x }

    assert_equal %i[actual x], expr.variables
    assert_equal %i[a b], expr.substitute(actual: :a, x: :b).variables
  end

  it '#evaluate' do
    expr = build { |_, foo:| [_, foo] }
    assert_equal [42, 'bar'], expr.evaluate({ actual: 42, foo: 'bar' })
  end

  it '#substitute' do
    expr = build { |_, x:, y:| _ * 100 + x * 10 + y }

    assert_equal 123, expr.evaluate({ actual: 1, x: 2, y: 3 })

    # x * 100 + y * 10 + _
    substituted = expr.substitute({ actual: :x, x: :y, y: :actual })

    assert_equal 231, substituted.evaluate({ actual: 1, x: 2, y: 3 })

    # y * 100 + _ * 10 + x
    substituted2 = substituted.substitute({ actual: :x, x: :y, y: :actual })

    assert_equal 312, substituted2.evaluate({ actual: 1, x: 2, y: 3 })
  end

  it '#to_s' do
    expr = build { |_, foo:| foo * Math.sqrt(_) }

    assert_equal 'expr { |_, foo:| ... }', expr.to_s
  end

  private

  def build(&block)
    Matcher::ProcExpression.new(block)
  end
end
