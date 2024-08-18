# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class ImplyOneMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'match none' do
      matcher = Matcher.build do
        imply_one(
          imply(String, 'string'),
          imply(Integer, 1),
        )
      end

      assert_errors matcher.match(:a),
        'expected :a to satisfy one of these conditions: String, Integer'
    end

    test 'match one' do
      matcher = Matcher.build do
        imply_one(
          imply(String, 'string'),
          imply(Integer, 1),
        )
      end

      assert_predicate matcher.match('string'), :valid?
      assert_predicate matcher.match(1), :valid?
      assert_not_predicate matcher.match(2), :valid?

      assert_errors matcher.match(2), 'expected 1 but got 2'
    end

    test 'match multiple' do
      matcher = Matcher.build do
        imply_one(
          imply(_[:foo] == true, partial_entries({ data: 'foo' })),
          imply(_[:bar] == true, partial_entries({ data: 'bar' })),
        )
      end

      assert_predicate matcher.match({ foo: true, data: 'foo' }), :valid?
      assert_predicate matcher.match({ bar: true, data: 'bar' }), :valid?
      assert_errors matcher.match({ foo: true, bar: true, data: 'bar' }),
        'expected {:foo=>true, :bar=>true, :data=>"bar"} to satisfy only one condition, but met these: actual[:foo] == true, actual[:bar] == true',
        data: 'expected "foo" but got "bar"'
    end

    test '#inspect' do
      matcher = Matcher.build do
        imply_one(
          imply(_[:type] == 'string', { data: 'foo' }),
          imply(_[:type] == 'integer', { data: 42 }),
        )
      end

      string = 'imply_one(imply(actual[:type] == "string", {:data=>"foo"}), imply(actual[:type] == "integer", {:data=>42}))'
      assert_equal string, matcher.inspect
    end
  end
end
