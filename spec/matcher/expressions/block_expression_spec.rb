# frozen_string_literal: true

require 'test_helper'

describe Matcher::BlockExpression do
  it '#variables' do
    expr = build { |_, x:| _ == x }

    assert_equal %i[actual x], expr.variables
  end

  it '#evaluate' do
    expr = build { |_, foo:| [_, foo] }
    assert_equal [42, 'bar'], expr.evaluate({ actual: 42, foo: 'bar' })
  end

  it '#to_s' do
    expr = build { |_, foo:| foo * Math.sqrt(_) }

    assert_equal 'expr { |_, foo:| ... }', expr.to_s

    expr = build(to_s: true) { |_, foo:| [_, foo] }

    assert_equal 'expr_s { |_, foo:| [_, foo] }', expr.to_s

    expr = build(to_s: true) { [_1] }

    assert_equal 'expr_s { [_1] }', expr.to_s
  end

  private

  def build(to_s: false, &block)
    Matcher::BlockExpression.new(block, to_s:)
  end
end
