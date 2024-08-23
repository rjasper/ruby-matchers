# frozen_string_literal: true

require 'test_helper'

module Matcher
  class BlockExpressionTest < ActiveSupport::TestCase
    test '#evaluate' do
      expr = BlockExpression.new { |_, foo:| [_, foo] }
      assert_equal [42, 'bar'], expr.evaluate({ actual: 42, foo: 'bar' })
    end

    test '#to_s' do
      expr = BlockExpression.new { |_, foo:| foo * Math.sqrt(_) }

      assert_equal 'expr { |_, foo:| ... }', expr.to_s

      expr = BlockExpression.new(to_s: true) { |_, foo:| [_, foo] }

      assert_equal 'expr_s { |_, foo:| [_, foo] }', expr.to_s

      expr = BlockExpression.new(to_s: true) { [_1] }

      assert_equal 'expr_s { [_1] }', expr.to_s
    end
  end
end
