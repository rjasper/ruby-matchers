# frozen_string_literal: true

require "test_helper"

describe Matcher::SetExpression do
  it "#variables" do
    expression = Matcher::Expression.build do
      Set[1, 2, vars[:foo]]
    end

    assert_equal %i[foo], expression.variables
  end

  it "#evaluate" do
    expression = Matcher::Expression.build do
      Set[1, 2, vars[:foo]]
    end

    assert_equal Set[1, 2, 3], expression.evaluate(foo: 3)
  end

  it "#substitute" do
    expression = Matcher::Expression.build do
      Set[1, 2, vars[:foo]]
    end

    expected = Matcher::Expression.build do
      Set[1, 2, vars[:bar]]
    end

    assert_equal expected, expression.substitute(foo: :bar)
  end

  it "#to_s" do
    expression = Matcher::Expression.build do
      Set[1, 2, vars[:foo]]
    end

    assert_equal "Set[1, 2, foo]", expression.to_s
  end
end
