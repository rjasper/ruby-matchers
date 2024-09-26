# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::MapMatcher do
  it 'matches mapped matcher' do
    projection = Matcher::Call.build { _1[:foo] }
    matcher = Matcher::MapMatcher.new(projection, a([v(1), v(2)]))

    assert_predicate matcher.match([{ foo: 1 }, { foo: 2 }]), :valid?
    refute_predicate matcher.match([]), :valid?
  end

  it 'generates error messages' do
    assert_errors match(nil) { map(_, [1]) },
      'expected to respond to "map" but got nil'
    assert_errors match([nil, nil]) { map(_[:foo], all) },
      0 => 'expected _ to respond to [] but got nil',
      1 => 'expected _ to respond to [] but got nil'
    assert_errors match([{ foo: 1 }, { foo: 3 }]) { map(_[:foo], [1, 2]) },
      1 => { foo: 'expected 2 but got 3' }
    assert_errors match([{ foo: 1 }, { foo: 1 }]) { map(_[:foo] + 1, [1, 2]) },
      0 => { foo: { expr { _1 + 1 } => 'expected 1 but got 2' } }
    assert_errors match([{ foo: 1 }, { foo: 1 }]) { map(_[:foo], _.is_a?(String)) },
      expr { _1.map_expression(_1[:foo]) } => 'expected _ to be a kind of String but got [1, 1]'
  end

  it 'pass index' do
    actual = [{ a: 10 }, { a: 20 }, { a: 40 }]

    projection = Matcher::Call.build(:actual, :index) { |_, i| _ + i }

    assert_errors match(actual) { map(_[:a] + i, [10, 21, 32]) },
      2 => { a: { projection => 'expected 32 but got 42' } }
  end

  it 'pass original' do
    matcher = Matcher.build do
      map(_[:a], [_ == original])
    end

    array = []
    array << { a: array }

    assert_predicate matcher.match(array), :valid?
    assert_errors matcher.match([{ a: 1 }]),
      0 => { a: 'expected _ to be original ([{:a=>1}]) but got 1' }
  end
end
