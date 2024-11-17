# frozen_string_literal: true

require 'test_helper'

describe Matcher::MapMatcher do
  it 'is built by map' do
    matcher = Matcher.build { map(_.length, [1, 2]) }

    assert_kind_of Matcher::MapMatcher, matcher
  end

  it 'expects actual to respond to :map' do
    matcher = Matcher.build { map(_.length, [1, 2]) }

    assert_expected_errors matcher.match(nil),
      "expected an object responding to `map' but got nil"
    assert_no_errors matcher.~.match(nil)
  end

  it 'rescues from call errors' do
    matcher = Matcher.build { map(_.length, [1]) }

    assert_expected_errors matcher.match([nil]),
      0 => "expected an object responding to `length' but got nil"
    assert_no_errors matcher.~.match([nil])
  end

  it 'matches mapped matcher' do
    matcher = Matcher.build { map(_.length, [1, 2]) }
    negated = ~matcher
    t = self

    assert_no_errors matcher.match([[1], [1, 2]])
    assert_expected_errors negated.match([[1], [1, 2]]) do
      _or do
        error t.expression { _[0].length }, 'did not expect 1'
        error t.expression { _[1].length }, 'did not expect 2'
      end
    end

    assert_expected_errors matcher.match([[1], [1, 2, 3]]),
      expression { _[1].length } => 'expected 2 but got 3'
    assert_no_errors negated.match([[1], [1, 2, 3]])
  end

  it 'maps base errors' do
    matcher = Matcher.build { map(_.length, _.sum == 4) }
    negated = ~matcher
    key = expression { _.map(&:length) }

    assert_no_errors matcher.match([[1], [2, 3], [4]])
    assert_expected_errors negated.match([[1], [2, 3], [4]]),
      key => 'expected _.sum != 4 but got 4 != 4, where _ = [1, 2, 1]'

    assert_expected_errors matcher.match([[1], [2, 3]]),
      key => 'expected _.sum == 4 but got 3 == 4, where _ = [1, 2]'
    assert_no_errors negated.match([[1], [2, 3]])
  end

  it 'maps functional error key' do
    matcher = Matcher.build do
      map(original.length * 100 + index * 10 + _, equal([209, 218]))
    end

    errors = matcher.match([9, 8, 7])

    assert_kind_of Matcher::Errors::Nested, errors
    assert_equal '_.map { |e| _.length * 100 + i * 10 + e }', errors.key.to_s
    assert_kind_of Matcher::Errors::Element, errors.node
    assert_equal 'expected [209, 218] but got [309, 318, 327]',
      Matcher::ExpectedPhrasing.new(nil, errors.node.message).apply
    assert_equal [309, 318, 327], errors.key.evaluate({ actual: [9, 8, 7] })
  end

  it 'passes index' do
    matcher = Matcher.build { map(_[:a] + i, [10, 21, 32]) }

    assert_expected_errors matcher.match([{ a: 10 }, { a: 20 }, { a: 40 }]),
      expression { _[2][:a] + i } => 'expected 32 but got 42'
  end

  it 'passes original' do
    matcher = Matcher.build do
      map(_[:a], [_ == original])
    end

    array = []
    array << { a: array }

    assert_no_errors matcher.match(array)
    assert_expected_errors matcher.match([{ a: 1 }]),
      0 => { a: 'expected _ == original but got 1 == [{:a=>1}]' }
  end

  it '#to_s' do
    matcher = Matcher.build { map(_.length, _.sum == 4) }

    assert_equal 'map(_.length, _.sum == 4)', matcher.to_s
    assert_equal '~map(_.length, _.sum == 4)', matcher.~.to_s
  end
end
