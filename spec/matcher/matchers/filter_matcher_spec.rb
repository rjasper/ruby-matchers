# frozen_string_literal: true

require 'test_helper'

describe Matcher::FilterMatcher do
  it 'is built by filter' do
    kind = Matcher::FilterMatcher

    assert_kind_of(kind, Matcher.build { filter(_.odd?, _ < 10) })
    assert_kind_of(kind, Matcher.build { filter(_.odd?) ^ (1 < 10) })
  end

  it 'matches filtered elements' do
    matcher = Matcher.build { filter(_.odd?) ^ each(_ < 10) }
    negated = ~matcher

    assert_no_errors matcher.match([7, 8, 9, 10])
    assert_or_errors negated.match([7, 8, 9, 10]),
      0 => msg(7).lower_than(10),
      2 => msg(9).lower_than(10)

    assert_errors matcher.match([7, 8, 9, 11]),
      3 => msg(11).not.lower_than(10)
    assert_no_errors negated.match([7, 8, 9, 11])

    assert_errors matcher.match(nil),
      msg(nil).not.responding_to(:each)
    assert_no_errors negated.match(nil)
  end

  it 'rescues from call errors' do
    matcher = Matcher.build { filter(expr(10) / _) ^ each(Integer) }
    negated = ~matcher

    assert_no_errors matcher.match([1, 2, 3])

    assert_errors matcher.match([0, 1, 2]),
      0 => 'did not expect 10 / _ to raise ZeroDivisionError, where _ = 0: divided by 0'
    assert_no_errors negated.match([0, 1, 2])
  end

  it 'maps base errors' do
    matcher = Matcher.build { filter(_.odd?) ^ (_.sum < 20) }
    negated = ~matcher
    filter = expression { _.filter(&:odd?) }

    assert_no_errors matcher.match([7, 8, 9, 10])
    assert_errors negated.match([7, 8, 9, 10]),
      filter => 'expected _.sum >= 20 but got 16 >= 20, where _ = [7, 9]'

    assert_errors matcher.match([7, 8, 9, 11]),
      filter => 'expected _.sum < 20 but got 27 < 20, where _ = [7, 9, 11]'
    assert_no_errors negated.match([7, 8, 9, 11])
  end

  it 'passes index to filter' do
    matcher = Matcher.build { filter(index.even?) ^ (_.join == '024') }
    filter_with_index = expression do
      _.filter.with_index { |e, index| index.even? }
    end

    assert_errors matcher.match([0, 1, 2, 3]),
      filter_with_index => 'expected _.join == "024" but got "02" == "024", where _ = [0, 2]'
  end

  it 'passes original to filter' do
    matcher = Matcher.build do
      filter(_ < original.sum.fdiv(original.length)) ^ (_.join == '12')
    end

    filter = expression do
      _.filter { |e| e < _.sum.fdiv(_.length) }
    end

    assert_errors matcher.match([1, 2, 3]), # sum = 6, average = 2
      filter => 'expected _.join == "12" but got "1" == "12", where _ = [1]'
  end

  it 'passes original to matcher' do
    matcher = Matcher.build { filter(_.odd?) ^ each(_ < original.sum / 2.0) }

    assert_errors matcher.match([1, 2, 3]), # sum = 6
      2 => 'expected _ < original.sum / 2.0 but got 3 < 3.0, where original = [1, 2, 3]'
  end

  it '#to_s' do
    assert_equal 'filter(_.odd?, _ < 10)',
      Matcher.build { filter(_.odd?, _ < 10) }.to_s
    assert_equal '~filter(_.odd?, _ < 10)',
      Matcher.build { ~filter(_.odd?, _ < 10) }.to_s
  end
end
