# frozen_string_literal: true

require 'test_helper'

describe Matcher::NegatedProjectMatcher do
  it 'match call' do
    my_struct = Struct.new(:value)

    matcher = Matcher.build do
      ~project(_.value, 'foo')
    end

    assert_expected_errors matcher.match(my_struct.new('foo')),
      expression { _.value } => 'did not expect "foo"'
    assert_no_errors matcher.match(my_struct.new('bar'))

    assert_no_errors matcher.match(my_struct.new('bar'))
    assert_no_errors matcher.match(1)
  end

  it '#to_s' do
    matcher = Matcher.build do
      ~project(_.my_method, 42)
    end

    assert_equal '~project(_.my_method, 42)', matcher.to_s
  end
end
