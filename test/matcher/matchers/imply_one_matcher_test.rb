# frozen_string_literal: true

require 'test_helper'

describe Matcher::ImplyOneMatcher do
  it 'match none' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    assert_expected_errors matcher.match(:a),
      'expected :a to satisfy one of these conditions: String, Integer'

    assert_no_errors matcher.match('string')
    assert_no_errors matcher.match(1)
  end

  it 'match else' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        else: nil,
      )
    end

    assert_no_errors matcher.match('string')
    assert_no_errors matcher.match(nil)

    assert_expected_errors matcher.match('foo'), 'expected "string" but got "foo"'
    assert_expected_errors matcher.match(1), 'expected nil but got 1'
  end

  it 'match one' do
    matcher = Matcher.build do
      imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    assert_no_errors matcher.match('string')
    assert_no_errors matcher.match(1)
    refute_predicate matcher.match(2), :valid?

    assert_expected_errors matcher.match(2), 'expected 1 but got 2'
  end

  it 'match multiple' do
    matcher = Matcher.build do
      imply_one(
        imply(_[:foo] == true, partial({ data: 'foo' })),
        imply(_[:bar] == true, partial({ data: 'bar' })),
      )
    end

    assert_no_errors matcher.match({ foo: true, data: 'foo' })
    assert_no_errors matcher.match({ bar: true, data: 'bar' })
    assert_expected_errors matcher.match({ foo: true, bar: true, data: 'bar' }),
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
