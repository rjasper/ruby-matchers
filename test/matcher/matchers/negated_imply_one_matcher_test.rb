# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::NegatedImplyOneMatcher do
  it 'match not one' do
    matcher = Matcher.build do
      ~imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    assert_predicate matcher.match(2), :valid?

    assert_errors matcher.match('string'),
      'expected "string" to not be "string"'
    assert_errors matcher.match(1),
      'expected 1 to not be 1'
  end

  it 'match not else' do
    matcher = Matcher.build do
      ~imply_one(
        imply(String, 'string'),
        else: nil,
      )
    end

    assert_errors matcher.match('string'), 'expected "string" to not be "string"'
    assert_errors matcher.match(nil), 'expected nil to not be nil'

    assert_predicate matcher.match('foo'), :valid?
    assert_predicate matcher.match(1), :valid?
  end

  it 'match not mutiple' do
    matcher = Matcher.build do
      ~imply_one(
        imply(_[:foo] == true, partial({ data: 'foo' })),
        imply(_[:bar] == true, partial({ data: 'bar' })),
      )
    end

    assert_predicate matcher.match({ foo: true, bar: true, data: 'bar' }), :valid?

    assert_errors matcher.match({ foo: true, data: 'foo' }),
      data: 'expected "foo" to not be "foo"'
    assert_errors matcher.match({ bar: true, data: 'bar' }),
      data: 'expected "bar" to not be "bar"'
  end

  it '#to_s' do
    matcher = Matcher.build do
      ~imply_one(
        imply(_[:type] == 'string', { data: 'foo' }),
        imply(_[:type] == 'integer', { data: 42 }),
      )
    end

    string = '~imply_one(imply(_[:type] == "string", {:data=>"foo"}), imply(_[:type] == "integer", {:data=>42}))'
    assert_equal string, matcher.to_s
  end
end
