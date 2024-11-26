# frozen_string_literal: true

require 'test_helper'

describe Matcher::VariableHole do
  include Matcher::PatternTesting

  describe '#to_s' do
    it 'looks like var(:key)' do
      assert_equal 'var(:foo)',
        Matcher::VariableHole.new(:foo).to_s
    end
  end

  it 'matches variable' do
    with_pattern -> { _ + var(:operand) } do
      assert_pattern_match _ + vars[:foo], operand: vars[:foo]

      assert_no_pattern_match _ + 1
      assert_no_pattern_match _ + (vars[:foo] - 1)
    end
  end
end
