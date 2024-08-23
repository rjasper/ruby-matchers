# frozen_string_literal: true

require 'test_helper'

class MatcherTest < ActiveSupport::TestCase
  test 'assert_structure' do
    assert_nothing_raised do
      assert_structure({ foo: 42 }) do
        { foo: 42 }
      end
    end

    assert_raises(Minitest::Assertion) do
      assert_structure({ bar: 1 }) do
        { bar: _.even? }
      end
    end
  end

  test 'checks unused refs' do
    assert_raises StandardError, match: 'unused ref: foo' do
      Matcher.build { refs[:foo] = 'foo'; 1 }
    end
  end

  test 'checks undefined refs' do
    assert_raises StandardError, match: 'undefined ref: foo' do
      Matcher.build { refs[:foo] }
    end
  end
end
