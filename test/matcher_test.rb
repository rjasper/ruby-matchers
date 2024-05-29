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
        { bar: value.even? }
      end
    end
  end
end
