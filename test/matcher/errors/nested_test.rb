# frozen_string_literal: true

require 'test_helper'

Nested = Matcher::Errors::Nested
Call = Matcher::Call

describe Matcher::Errors::Nested do
  it '::from: simple key' do
    assert_equal Nested.new(expression { _[:foo] }, element('foo is wrong')),
      Nested.from(:foo, element('foo is wrong'))
  end

  it '::from: empty error' do
    assert_equal empty, Nested.from(:foo, empty)
  end

  it '::from: expression key' do
    exp = expression { _ + 1 }

    assert_equal Nested.new(exp, element('something went wrong')),
      Nested.from(exp, element('something went wrong'))
  end

  it '::from: constant expression root' do
    math = Matcher::Constant.new(Math)
    actual = Matcher::Variable.actual
    expression = Matcher::Call.new(math, :sqrt, [actual])
    element = Matcher::Errors::Element.new('something went wrong')

    assert_equal Nested.new(expression, element),
      Nested.from(expression, element)
  end

  it '::from: root expression key' do
    assert_equal element('something went wrong'),
      Nested.from(Variable.actual, element('something went wrong'))
  end
end
