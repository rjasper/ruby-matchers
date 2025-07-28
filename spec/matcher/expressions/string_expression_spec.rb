# frozen_string_literal: true

require 'test_helper'

describe Matcher::StringExpression do
  it '#variables' do
    expression = Matcher::Expression.build { concat(vars[:foo], 'bar') }

    assert_equal %i[foo], expression.variables
  end

  it '#evaluate' do
    expression = Matcher::Expression.build { concat(vars[:foo], 'bar') }

    assert_equal 'foobar', expression.evaluate(foo: 'foo')
  end

  it '#substitute' do
    expression = Matcher::Expression.build { concat(vars[:foo], 'bar') }
    expected = Matcher::Expression.build { concat(vars[:bar], 'bar') }

    assert_equal expected, expression.substitute(foo: :bar)
  end

  it '#to_s' do
    expression = Matcher::Expression.build { concat(vars[:foo] * 2, 'bar') }

    assert_equal '"#{foo * 2}bar"', expression.to_s
  end
end
