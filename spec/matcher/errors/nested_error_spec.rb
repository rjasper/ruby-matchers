# frozen_string_literal: true

require 'test_helper'

describe Matcher::NestedError do
  include Matcher::ErrorTesting

  it '::from: simple key' do
    assert_equal nested(expression { _[:foo] }, element('foo is wrong')),
      nested_from(:foo, element('foo is wrong'))
  end

  it '::from: empty error' do
    assert_equal empty, nested_from(:foo, empty)
  end

  it '::from: expression key' do
    exp = expression { _ + 1 }

    assert_equal nested(exp, element('something went wrong')),
      nested_from(exp, element('something went wrong'))
  end

  it '::from: constant expression root' do
    math = Matcher::Constant.new(Math)
    actual = Matcher::Variable.actual
    expression = Matcher::Call.new(math, :sqrt, [actual])
    element = Matcher::ElementError.new('something went wrong')

    assert_equal nested(expression, element),
      nested_from(expression, element)
  end

  it '::from: root expression key' do
    assert_equal element('something went wrong'),
      nested_from(Matcher::Variable.actual, element('something went wrong'))
  end
end
