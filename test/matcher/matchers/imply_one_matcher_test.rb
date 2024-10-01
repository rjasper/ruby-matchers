# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::ImplyOneMatcher do
  it 'match none' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    assert_errors matcher.match(:a),
      'expected :a to satisfy one of these conditions: String, Integer'

    assert_predicate matcher.match('string'), :valid?
    assert_predicate matcher.match(1), :valid?
  end

  it 'match else' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        else: nil,
      )
    end

    assert_predicate matcher.match('string'), :valid?
    assert_predicate matcher.match(nil), :valid?

    assert_errors matcher.match('foo'), 'expected "string" but got "foo"'
    assert_errors matcher.match(1), 'expected nil but got 1'
  end

  it 'match one' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    assert_predicate matcher.match('string'), :valid?
    assert_predicate matcher.match(1), :valid?
    refute_predicate matcher.match(2), :valid?

    assert_errors matcher.match(2), 'expected 1 but got 2'
  end

  it 'match multiple' do
    matcher = Matcher.build do
      imply_one(
        imply(_[:foo] == true, partial_entries({ data: 'foo' })),
        imply(_[:bar] == true, partial_entries({ data: 'bar' })),
      )
    end

    assert_predicate matcher.match({ foo: true, data: 'foo' }), :valid?
    assert_predicate matcher.match({ bar: true, data: 'bar' }), :valid?
    assert_errors matcher.match({ foo: true, bar: true, data: 'bar' }),
      'expected {:foo=>true, :bar=>true, :data=>"bar"} to satisfy only one condition, but met these: _[:foo] == true, _[:bar] == true',
      data: 'expected "foo" but got "bar"'
  end

  it '#to_s' do
    matcher = Matcher.build do
      imply_one(
        imply(_[:type] == 'string', { data: 'foo' }),
        imply(_[:type] == 'integer', { data: 42 }),
      )
    end

    string = 'imply_one(imply(_[:type] == "string", {:data=>"foo"}), imply(_[:type] == "integer", {:data=>42}))'
    assert_equal string, matcher.to_s
  end
end
