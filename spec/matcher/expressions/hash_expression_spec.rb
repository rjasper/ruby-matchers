# frozen_string_literal: true

require 'test_helper'

describe Matcher::HashExpression do
  it '#variables' do
    expression = Matcher::Expression.build { { vars[:foo] => vars[:bar] } }

    assert_equal %i[foo bar], expression.variables
  end

  it '#evaluate' do
    expression = Matcher::Expression.build { { vars[:foo] => vars[:bar] } }

    assert_equal({ 1 => 2 }, expression.evaluate(foo: 1, bar: 2))
  end

  it '#bind' do
    expression = Matcher::Expression.build { { vars[:foo] => vars[:bar] } }
    expected = Matcher::Expression.build do
      {
        Matcher::Variable.new(:foo).bind(foo: 1) =>
          Matcher::Variable.new(:bar).bind(bar: 2),
      }
    end

    assert_equal expected, expression.bind(foo: 1, bar: 2)
  end

  it '#substitute' do
    expression = Matcher::Expression.build { { vars[:foo] => vars[:bar] } }
    expected = Matcher::Expression.build { { vars[:bar] => vars[:foo] } }

    assert_equal expected, expression.substitute(foo: :bar, bar: :foo)
  end

  it '#to_s' do
    expression = Matcher::Expression.build { { vars[:foo] => vars[:bar] } }

    assert_equal '{ foo => bar }', expression.to_s
  end
end
