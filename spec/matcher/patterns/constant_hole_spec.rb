# frozen_string_literal: true

require 'test_helper'

describe Matcher::ConstantHole do
  include Matcher::PatternHelpers

  describe '#to_s' do
    it 'looks like const(:key)' do
      assert_equal 'const(:foo)',
        Matcher::ConstantHole.new(:foo).to_s
    end
  end

  it 'matches constant' do
    with_pattern -> { _ + const(:operand) } do
      assert_pattern_match _ + 1, operand: 1

      assert_no_pattern_match _ + vars[:foo]
      assert_no_pattern_match _ + (vars[:foo] - 1)
    end
  end
end
