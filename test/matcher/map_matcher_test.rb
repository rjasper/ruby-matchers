# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class MapMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'matches mapped matcher' do
      projection = Call.build { _1[:foo] }
      matcher = MapMatcher.new(projection, a([v(1), v(2)]))

      assert_predicate matcher.match([{ foo: 1 }, { foo: 2 }]), :valid?
      assert_not_predicate matcher.match([]), :valid?
    end

    test 'generates error messages' do
      assert_errors match(nil) { map(_, [1]) },
        'expected to respond to "map" but got nil'
      assert_errors match([nil, nil]) { map(_[:foo], all) },
        0 => 'expected actual to respond to [] but got nil',
        1 => 'expected actual to respond to [] but got nil'
      assert_errors match([{ foo: 1 }, { foo: 3 }]) { map(_[:foo], [1, 2]) },
        1 => { foo: 'expected 2 but got 3' }
      assert_errors match([{ foo: 1 }, { foo: 1 }]) { map(_[:foo] + 1, [1, 2]) },
        0 => { foo: { expr { _1 + 1 } => 'expected 1 but got 2' } }
      assert_errors match([{ foo: 1 }, { foo: 1 }]) { map(_[:foo], _.is_a?(String)) },
        expr { _1.map_expression(_1[:foo]) } => 'expected actual to be a kind of String but got [1, 1]'
    end
  end
end
