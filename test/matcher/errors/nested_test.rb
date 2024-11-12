# frozen_string_literal: true

require 'test_helper'

Nested = Matcher::Errors::Nested
Call = Matcher::Call

describe Matcher::Errors::Nested do
  it '::from: simple key' do
    assert_equal Nested.new(Call.build { _1[:foo] }, element('foo is wrong')),
      Nested.from(:foo, element('foo is wrong'))
  end

  it '::from: empty error' do
    assert_equal empty, Nested.from(:foo, empty)
  end

  it '::from: expression key' do
    expression = Call.build { _1 + 1 }

    assert_equal Nested.new(expression, element('something went wrong')),
      Nested.from(expression, element('something went wrong'))
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
    expression = Call.build { _1 }

    assert_equal element('something went wrong'),
      Nested.from(expression, element('something went wrong'))
  end
end
