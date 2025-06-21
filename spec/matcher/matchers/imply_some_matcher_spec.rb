# frozen_string_literal: true

require 'test_helper'

describe Matcher::ImplySomeMatcher do
  it 'is built by imply_one' do
    matcher = Matcher.build do
      imply_one(
        of(String) >> 'string',
        of(Integer) >> 1,
      )
    end

    assert_kind_of Matcher::ImplySomeMatcher, matcher
  end

  it 'matches none' do
    matcher = Matcher.build do
      imply_one(
        of(String) >> 'string',
        of(Integer) >> 1,
      )
    end

    negated = ~matcher

    assert_errors matcher.match(:a),
      'expected to satisfy one condition but got :a and met none of these: String, Integer'
    assert_no_errors negated.match(:a)
  end

  it 'matches one' do
    matcher = Matcher.build do
      imply_one(
        of(String) >> 'string',
        of(Integer) >> 1,
      )
    end

    negated = ~matcher

    assert_no_errors matcher.match('string')
    assert_errors negated.match('string'),
      msg('string').equal('string')

    assert_no_errors matcher.match(1)
    assert_errors negated.match(1),
      msg(1).equal(1)

    assert_errors matcher.match('text'),
      msg('text').not.equal('string')
    assert_no_errors negated.match('text')

    assert_errors matcher.match(2),
      msg(2).not.equal(1)
    assert_no_errors negated.match(2)
  end

  it 'matches any' do
    matcher = Matcher.build do
      imply_any(
        partial(divisible_by: Integer) >> partial(value: _ % parent[:divisible_by] == 0),
        partial(odd: true) >> partial(value: _.odd?),
      )
    end

    negated = ~matcher

    assert_no_errors matcher.match({ divisible_by: 3, value: 6 })
    assert_errors negated.match({ divisible_by: 3, value: 6 }),
      value: 'expected _ % parent[:divisible_by] != 0 but got 0 != 0, where _ = 6, parent = {:divisible_by=>3, :value=>6}'

    assert_errors matcher.match({ divisible_by: 3, odd: true, value: 6 }),
      value: 'expected value to be odd but got 6'
    assert_no_errors negated.match({ divisible_by: 3, odd: true, value: 6 })

    assert_errors matcher.match({ divisible_by: 3, odd: true, value: 5 }),
      value: 'expected _ % parent[:divisible_by] == 0 but got 2 == 0, where _ = 5, parent = {:divisible_by=>3, :odd=>true, :value=>5}'
    assert_no_errors negated.match({ divisible_by: 3, odd: true, value: 5 })

    assert_errors matcher.match({}),
      'expected to satisfy any condition but got {} and met none of these: partial({:divisible_by=>Integer}), partial({:odd=>true})'
    assert_no_errors negated.match({})
  end

  it 'matches multiple' do
    matcher = Matcher.build do
      imply_one(
        of(_[:foo] == true) >> partial({ data: 'foo' }),
        of(_[:bar] == true) >> partial({ data: 'bar' }),
      )
    end

    negated = ~matcher

    assert_errors matcher.match({ foo: true, bar: true, data: 'bar' }),
      'expected to satisfy one condition but got {:foo=>true, :bar=>true, :data=>"bar"} and met these: _[:foo] == true, _[:bar] == true',
      data: msg('bar').not.equal('foo')
    assert_no_errors negated.match({ foo: true, bar: true, data: 'bar' })
  end

  it 'matches with else' do
    matcher = Matcher.build do
      imply_one(
        of(String) >> 'string',
        else: nil,
      )
    end

    negated = ~matcher

    assert_no_errors matcher.match('string')
    assert_errors negated.match('string'),
      msg('string').equal('string')

    assert_no_errors matcher.match(nil)
    assert_errors negated.match(nil),
      msg(nil).equal(nil)

    assert_errors matcher.match('foo'),
      msg('foo').not.equal('string')
    assert_no_errors negated.match('foo')

    assert_errors matcher.match(1),
      msg(1).not.equal(nil)
    assert_no_errors negated.match(1)
  end

  it '#to_s' do
    assert_equal 'imply_one(imply(String, "string"), imply(Integer, 1))',
      Matcher.build { imply_one(of(String) >> 'string', of(Integer) >> 1) }.to_s
    assert_equal 'imply_any(imply(String, "string"), imply(Integer, 1))',
      Matcher.build { imply_any(of(String) >> 'string', of(Integer) >> 1) }.to_s
    assert_equal 'imply_some(imply(String, "string"), imply(Integer, 1), count: 2)',
      Matcher.build { imply_some(of(String) >> 'string', of(Integer) >> 1, count: 2) }.to_s

    assert_equal 'imply_one(imply(String, "string"), else: nil)',
      Matcher.build { imply_one(of(String) >> 'string', else: nil) }.to_s

    assert_equal '~imply_one(imply(String, "string"), imply(Integer, 1))',
      Matcher.build { ~imply_one(of(String) >> 'string', of(Integer) >> 1) }.to_s
  end
end
