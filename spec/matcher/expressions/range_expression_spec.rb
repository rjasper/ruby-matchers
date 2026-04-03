# frozen_string_literal: true

require "test_helper"

describe Matcher::RangeExpression do
  it "#variables" do
    expression = Matcher::Expression.build { vars[:foo]..vars[:bar] }

    assert_equal %i[foo bar], expression.variables
  end

  it "#evaluate" do
    expression1 = Matcher::Expression.build { vars[:foo]..vars[:bar] }
    expression2 = Matcher::Expression.build { vars[:foo]...vars[:bar] }

    assert_equal 1..2, expression1.evaluate(foo: 1, bar: 2)
    assert_equal 1...2, expression2.evaluate(foo: 1, bar: 2)
  end

  it "#substitute" do
    expression = Matcher::Expression.build { vars[:foo]..vars[:bar] }
    expected = Matcher::Expression.build { vars[:bar]..vars[:foo] }

    assert_equal expected, expression.substitute(foo: :bar, bar: :foo)
  end

  it "#to_s" do
    expression = Matcher::Expression.build { vars[:foo]..vars[:bar] }

    assert_equal "foo..bar", expression.to_s

    expression = Matcher::Expression.build { vars[:foo]...vars[:bar] }

    assert_equal "foo...bar", expression.to_s

    expression = Matcher::Expression.build { range(vars[:a], vars[:b]).to_a }

    assert_equal "(a..b).to_a", expression.to_s
  end
end
