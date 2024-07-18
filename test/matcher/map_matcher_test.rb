# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class MapMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'matches mapped matcher' do
      value = ExpressionRecorder.new
      projection = ExpressionRecorder.to_expression(value[:foo])
      matcher = MapMatcher.new(projection, a([v(1), v(2)]))

      assert_predicate matcher.match([{ foo: 1 }, { foo: 2 }]), :valid?
      assert_not_predicate matcher.match([]), :valid?
    end

    test 'generates error messages' do
      assert_errors match(nil) { map(value, [1]) },
        'expected to respond to "map" but got nil'
      assert_errors match([nil, nil]) { map(value[:foo], all) },
        0 => 'expected value to respond to [] but got nil',
        1 => 'expected value to respond to [] but got nil'
      assert_errors match([{ foo: 1 }, { foo: 3 }]) { map(value[:foo], [1, 2]) },
        1 => 'expected 2 but got 3'
      assert_errors match([{ foo: 1 }, { foo: 1 }]) { map(value[:foo] + 1, [1, 2]) },
        0 => 'expected 1 but got 2'
    end
  end
end
