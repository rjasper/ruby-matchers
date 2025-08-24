# frozen_string_literal: true

require 'test_helper'

describe Matcher::RescueLastErrorExpression do
  it '#variables' do
    expression = Matcher::Expression.build do
      rescue_exception(vars[:foo] + vars[:bar])
    end

    assert_equal %i[foo bar], expression.variables
  end

  it '#evaluate' do
    expr = Matcher::Expression.build do
      rescue_exception(vars[:a] / vars[:b])
    end

    assert_equal 5, expr.evaluate(a: 10, b: 2)
    assert_kind_of ZeroDivisionError, expr.evaluate(a: 10, b: 0)
  end

  it '#substitute' do
    expression = Matcher::Expression.build do
      rescue_exception(vars[:a] + vars[:b])
    end

    expected = Matcher::Expression.build do
      rescue_exception(vars[:foo] + vars[:bar])
    end

    assert_equal expected, expression.substitute(a: :foo, b: :bar)
  end

  it '#to_s' do
    expression = Matcher::Expression.build do
      rescue_exception(vars[:a] + vars[:b])
    end

    assert_equal 'a + b rescue $!', expression.to_s
  end
end
