# frozen_string_literal: true

require 'test_helper'

describe Matcher::ImplyOneMatcher do
  it 'is built by imply_one' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    assert_kind_of Matcher::ImplyOneMatcher, matcher
  end

  it 'matches none' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    negated = ~matcher

    assert_errors matcher.match(:a),
      'expected :a to satisfy one of these conditions: String, Integer'
    assert_no_errors negated.match(:a)
  end

  it 'matches one' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    negated = ~matcher

    assert_no_errors matcher.match('string')
    assert_errors negated.match('string'),
      'did not expect "string"'

    assert_no_errors matcher.match(1)
    assert_errors negated.match(1),
      'did not expect 1'

    assert_errors matcher.match('text'),
      'expected "string" but got "text"'
    assert_no_errors negated.match('text')

    assert_errors matcher.match(2),
      'expected 1 but got 2'
    assert_no_errors negated.match(2)
  end

  it 'matches multiple' do
    matcher = Matcher.build do
      imply_one(
        imply(_[:foo] == true, partial({ data: 'foo' })),
        imply(_[:bar] == true, partial({ data: 'bar' })),
      )
    end

    negated = ~matcher

    assert_errors matcher.match({ foo: true, bar: true, data: 'bar' }),
      'expected {:foo=>true, :bar=>true, :data=>"bar"} to satisfy only one condition, but met these: _[:foo] == true, _[:bar] == true',
      data: 'expected "foo" but got "bar"'
    assert_no_errors negated.match({ foo: true, bar: true, data: 'bar' })
  end

  it 'matches with else' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        else: nil,
      )
    end

    negated = ~matcher

    assert_no_errors matcher.match('string')
    assert_errors negated.match('string'),
      'did not expect "string"'

    assert_no_errors matcher.match(nil)
    assert_errors negated.match(nil),
      'did not expect nil'

    assert_errors matcher.match('foo'),
      'expected "string" but got "foo"'
    assert_no_errors negated.match('foo')

    assert_errors matcher.match(1),
      'expected nil but got 1'
    assert_no_errors negated.match(1)
  end

  it '#to_s' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    assert_equal 'imply_one(imply(String, "string"), imply(Integer, 1))', matcher.to_s
    assert_equal '~imply_one(imply(String, "string"), imply(Integer, 1))', matcher.~.to_s
  end
end
