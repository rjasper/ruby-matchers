# frozen_string_literal: true

require 'test_helper'

describe Matcher::NegatedImplyOneMatcher do
  it 'match not one' do
    matcher = Matcher.build do
      ~imply_one(
        imply(String, 'string'),
        imply(Integer, 1),
      )
    end

    assert_no_errors matcher.match(2)

    assert_expected_errors matcher.match('string'),
      'did not expect "string"'
    assert_expected_errors matcher.match(1),
      'did not expect 1'
  end

  it 'match not else' do
    matcher = Matcher.build do
      ~imply_one(
        imply(String, 'string'),
        else: nil,
      )
    end

    assert_expected_errors matcher.match('string'), 'did not expect "string"'
    assert_expected_errors matcher.match(nil), 'did not expect nil'

    assert_no_errors matcher.match('foo')
    assert_no_errors matcher.match(1)
  end

  it 'match not mutiple' do
    matcher = Matcher.build do
      ~imply_one(
        imply(_[:foo] == true, partial({ data: 'foo' })),
        imply(_[:bar] == true, partial({ data: 'bar' })),
      )
    end

    assert_no_errors matcher.match({ foo: true, bar: true, data: 'bar' })

    assert_expected_errors matcher.match({ foo: true, data: 'foo' }),
      data: 'did not expect "foo"'
    assert_expected_errors matcher.match({ bar: true, data: 'bar' }),
      data: 'did not expect "bar"'
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
