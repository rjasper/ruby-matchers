# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::MapMatcher do
  it 'matches not mapped matcher' do
    matcher = Matcher.build do
      ~map(_[:foo], [1, 2])
    end

    assert_errors matcher.match([{ foo: 1 }, { foo: 2 }]) do
      _or do
        error [0, :foo], 'expected 1 to not be 1'
        error [1, :foo], 'expected 2 to not be 2'
      end
    end

    assert_predicate matcher.match([]), :valid?
  end
end
