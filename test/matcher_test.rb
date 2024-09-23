# frozen_string_literal: true

require 'test_helper'

describe Matcher do
  it 'assert_structure' do
    assert_structure({ foo: 42 }) do
      { foo: 42 }
    end

    assert_raises(Minitest::Assertion) do
      assert_structure({ bar: 1 }) do
        { bar: _.even? }
      end
    end
  end

  it 'checks unused refs' do
    assert_raises StandardError, match: 'unused ref: foo' do
      Matcher.build { refs[:foo] = 'foo'; 1 }
    end
  end

  it 'checks undefined refs' do
    assert_raises StandardError, match: 'undefined ref: foo' do
      Matcher.build { refs[:foo] }
    end
  end
end
