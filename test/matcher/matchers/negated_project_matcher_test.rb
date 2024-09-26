# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::NegatedProjectMatcher do
  it 'match call' do
    my_struct = Struct.new(:value)

    matcher = Matcher.build do
      ~project(_.value, 'foo')
    end

    assert_errors matcher.match(my_struct.new('foo')),
      expr { _1.value } => 'expected "foo" to not be "foo"'
    assert_predicate matcher.match(my_struct.new('bar')), :valid?

    assert_predicate matcher.match(my_struct.new('bar')), :valid?
    assert_predicate matcher.match(1), :valid?
  end

  it '#to_s' do
    matcher = Matcher.build do
      ~project(_.my_method, 42)
    end

    assert_equal '~project(_.my_method, 42)', matcher.to_s
  end
end
