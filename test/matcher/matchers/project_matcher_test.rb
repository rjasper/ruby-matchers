# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class ProjectMatcherTest < ActiveSupport::TestCase
    include Matcher::Testing

    test 'match call' do
      MyStruct = Struct.new(:value)

      matcher = Matcher.build do
        project(_.value, 'foo')
      end

      assert_predicate matcher.match(MyStruct.new('foo')), :valid?
      assert_not_predicate matcher.match(MyStruct.new('bar')), :valid?

      assert_errors matcher.match(MyStruct.new('bar')),
        expr { _1.value } => 'expected "foo" but got "bar"'
      assert_errors matcher.match(1),
        'expected _ to respond to value but got 1'

      negated = ~matcher

      assert_errors negated.match(MyStruct.new('foo')),
        expr { _1.value } => 'expected "foo" to not be "foo"'
      assert_predicate negated.match(MyStruct.new('bar')), :valid?

      assert_predicate negated.match(MyStruct.new('bar')), :valid?
      assert_predicate negated.match(1), :valid?
    end

    test '#to_s' do
      matcher = Matcher.build do
        project(_.my_method, 42)
      end

      assert_equal 'project(_.my_method, 42)', matcher.to_s
    end
  end
end
