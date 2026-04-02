# frozen_string_literal: true

require "test_helper"

describe Matcher::ArrayExpression do
  it "#variables" do
    expression = Matcher::Expression.build { [vars[:foo], [vars[:bar]]] }

    assert_equal %i[foo bar], expression.variables
  end

  it "#evaluate" do
    expression = Matcher::Expression.build { [vars[:foo], [vars[:bar]]] }

    assert_equal [1, [2]], expression.evaluate(foo: 1, bar: 2)
  end

  it "#substitute" do
    expression = Matcher::Expression.build { [vars[:foo], [vars[:bar]]] }
    expected = Matcher::Expression.build { [vars[:bar], [vars[:foo]]] }

    assert_equal expected, expression.substitute(foo: :bar, bar: :foo)
  end

  it "#to_s" do
    expression = Matcher::Expression.build { [vars[:foo], [vars[:bar]], :qux] }

    assert_equal "[foo, [bar], :qux]", expression.to_s
  end
end
