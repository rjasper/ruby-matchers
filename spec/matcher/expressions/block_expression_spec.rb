# frozen_string_literal: true

require 'test_helper'

describe Matcher::BlockExpression do
  it '#evaluate' do
    expr = Matcher::BlockExpression.new { |_, foo:| [_, foo] }
    assert_equal [42, 'bar'], expr.evaluate({ actual: 42, foo: 'bar' })
  end

  it '#to_s' do
    expr = Matcher::BlockExpression.new { |_, foo:| foo * Math.sqrt(_) }

    assert_equal 'expr { |_, foo:| ... }', expr.to_s

    expr = Matcher::BlockExpression.new(to_s: true) { |_, foo:| [_, foo] }

    assert_equal 'expr_s { |_, foo:| [_, foo] }', expr.to_s

    expr = Matcher::BlockExpression.new(to_s: true) { [_1] }

    assert_equal 'expr_s { [_1] }', expr.to_s
  end
end
