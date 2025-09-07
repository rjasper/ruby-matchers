# frozen_string_literal: true

require 'test_helper'

describe Matcher::ParseIntegerMatcher do
  it 'is built by parse_integer' do
    matcher = Matcher.build { parse_integer(_.even?) }

    assert_kind_of Matcher::ParseIntegerMatcher, matcher

    matcher = Matcher.build { parse_integer ^ _.even? }

    assert_kind_of Matcher::ParseIntegerMatcher, matcher
  end

  it 'matches integer from string' do
    matcher = Matcher.build { parse_integer(_.even?) }
    negated = ~matcher

    integer_of = expression { kernel::Integer(_) }

    assert matcher.match?('2')
    assert_no_errors matcher.match('2')
    refute negated.match?('2')
    assert_errors negated.match('2'),
      integer_of => msg(2).predicate(:even?)

    refute matcher.match?('foo')
    assert_errors matcher.match('foo'),
      msg('foo').not.valid_format(:integer)
    assert negated.match?('foo')
    assert_no_errors negated.match('foo')

    refute matcher.match?('3')
    assert_errors matcher.match('3'),
      integer_of => msg(3).not.predicate(:even?)
    assert negated.match?('3')
    assert_no_errors negated.match('3')
  end

  it 'matches integer format' do
    matcher = Matcher.build { integer_format }
    negated = ~matcher

    assert matcher.match?('2')
    assert_no_errors matcher.match('2')
    refute negated.match?('2')
    assert_errors negated.match('2'),
      msg('2').valid_format(:integer)

    refute matcher.match?('foo')
    assert_errors matcher.match('foo'),
      msg('foo').not.valid_format(:integer)
    assert negated.match?('foo')
    assert_no_errors negated.match('foo')
  end

  it '#to_s' do
    assert_equal 'parse_integer(_.even?)',
      Matcher.build { parse_integer(_.even?) }.to_s
    assert_equal '~parse_integer(_.even?)',
      Matcher.build { ~parse_integer(_.even?) }.to_s
    assert_equal 'parse_integer(_.even?, base: 2)',
      Matcher.build { parse_integer(_.even?, base: 2) }.to_s

    assert_equal 'integer_format',
      Matcher.build { integer_format }.to_s
    assert_equal '~integer_format',
      Matcher.build { ~integer_format }.to_s
    assert_equal 'integer_format(base: 2)',
      Matcher.build { integer_format(base: 2) }.to_s
  end
end
