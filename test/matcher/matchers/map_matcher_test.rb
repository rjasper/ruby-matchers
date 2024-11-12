# frozen_string_literal: true

require 'test_helper'

describe Matcher::MapMatcher do
  it 'matches mapped matcher' do
    projection = expression { _[:foo] }
    matcher = Matcher::MapMatcher.new(projection, a([v(1), v(2)]))

    assert_predicate matcher.match([{ foo: 1 }, { foo: 2 }]), :valid?
    refute_predicate matcher.match([]), :valid?
  end

  it 'generates error messages' do
    assert_expected_errors match(nil) { map(_, [1]) },
      "expected an object responding to `map' but got nil"
    assert_expected_errors match([nil, nil]) { map(_[:foo], all) },
      0 => "expected an object responding to `[]' but got nil",
      1 => "expected an object responding to `[]' but got nil"
    assert_expected_errors match([{ foo: 1 }, { foo: 3 }]) { map(_[:foo], [1, 2]) },
      1 => { foo: 'expected 2 but got 3' }
    assert_expected_errors match([{ foo: 1 }, { foo: 1 }]) { map(_[:foo] + 1, [1, 2]) },
      0 => { foo: { expression { _ + 1 } => 'expected 1 but got 2' } }

    key = expression { _.map { |e| e[:foo] } }

    assert_expected_errors match([{ foo: 1 }, { foo: 1 }]) { map(_[:foo], _.sum == 3) },
      key => 'expected _.sum == 3 but got 2 == 3, where _ = [1, 1]'
  end

  it 'nested error key evaluates to mapped actual' do
    matcher = Matcher.build do
      map(original.length * 100 + index * 10 + _, equal([209, 218]))
    end

    actual = [9, 8, 7]
    errors = matcher.match(actual)

    assert_kind_of Matcher::Errors::Nested, errors
    assert_equal '_.map { |e| _.length * 100 + i * 10 + e }', errors.key.to_s
    assert_kind_of Matcher::Errors::Element, errors.node
    assert_equal msg_not(:equal, [309, 318, 327], [209, 218]), errors.node.message
    assert_equal [309, 318, 327], errors.key.evaluate({ actual: })
  end

  it 'pass index' do
    actual = [{ a: 10 }, { a: 20 }, { a: 40 }]

    projection = expression { _ + i }

    assert_expected_errors match(actual) { map(_[:a] + i, [10, 21, 32]) },
      2 => { a: { projection => 'expected 32 but got 42' } }
  end

  it 'pass original' do
    matcher = Matcher.build do
      map(_[:a], [_ == original])
    end

    array = []
    array << { a: array }

    assert_predicate matcher.match(array), :valid?
    assert_expected_errors matcher.match([{ a: 1 }]),
      0 => { a: 'expected _ == original but got 1 == [{:a=>1}]' }
  end
end
