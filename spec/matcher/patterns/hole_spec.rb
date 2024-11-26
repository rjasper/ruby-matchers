# frozen_string_literal: true

require 'test_helper'

describe Matcher::Hole do
  include Matcher::PatternTesting

  describe '#to_s' do
    it 'looks like hole(:key)' do
      assert_equal 'hole(:foo)', Matcher::Hole.new(:foo).to_s
    end
  end

  it 'matches any expression' do
    with_pattern -> { _ + hole(:operand) } do
      assert_pattern_match _ + 1, operand: 1
      assert_pattern_match _ + vars[:foo], operand: vars[:foo]
      assert_pattern_match _ + (vars[:foo] + 1), operand: vars[:foo] + 1

      assert_no_pattern_match _ - 1
    end
  end
end
