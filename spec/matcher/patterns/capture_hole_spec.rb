# frozen_string_literal: true

require "test_helper"

describe Matcher::CaptureHole do
  include Matcher::PatternTesting

  describe "#to_s" do
    it "looks like capture(:key, pattern)" do
      one = Matcher::Constant.new(1)

      assert_equal "capture(:foo, 1)",
        Matcher::CaptureHole.new(:foo, one).to_s
    end
  end

  it "captures given pattern" do
    with_pattern -> { _ + capture(:operand, var(:variable) * 2) } do
      assert_pattern_match _ + vars[:foo] * 2, operand: vars[:foo] * 2, variable: vars[:foo]

      assert_no_pattern_match _ + (vars[:foo] - 1) * 2
    end
  end
end
