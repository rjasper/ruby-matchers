# frozen_string_literal: true

require 'test_helper'

describe Matcher::MapMatcher do
  it 'matches not mapped matcher' do
    matcher = Matcher.build do
      ~map(_[:foo], [1, 2])
    end

    assert_expected_errors matcher.match([{ foo: 1 }, { foo: 2 }]) do
      _or do
        error [0, :foo], 'did not expect 1'
        error [1, :foo], 'did not expect 2'
      end
    end

    assert_no_errors matcher.match([])
  end
end
