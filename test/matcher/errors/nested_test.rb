# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  module Errors
    class NestedTest < ActiveSupport::TestCase
      include Testing

      test '::from: simple expression key' do
        assert_equal nested(:foo, element('foo is wrong')),
          Nested.from(Call.build { _1[:foo] }, element('foo is wrong'))
      end

      test '::from: chained expression key' do
        assert_equal nested(:foo, nested(:bar, element('foo is wrong'))),
          Nested.from(Call.build { _1[:foo][:bar] }, element('foo is wrong'))
      end

      test '::from: advanced expression key' do
        expression = Call.build { _1 + 1 }

        assert_equal nested(expression, element('something went wrong')),
          Nested.from(expression, element('something went wrong'))
      end

      test '::from: constant expression root' do
        math = Constant.new(Math)
        actual = Variable.new(:actual)
        expression = Call.new(math, :sqrt, actual)
        element = Element.new('something went wrong')

        assert_equal Nested.new(expression, element),
          Nested.from(expression, element)
      end

      test '::from: root expression key' do
        expression = Call.build { _1 }

        assert_equal element('something went wrong'),
          Nested.from(expression, element('something went wrong'))
      end
    end
  end
end
