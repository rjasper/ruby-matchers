# frozen_string_literal: true

require 'test_helper'

describe Matcher::Pattern::PatternBuilder do
  let(:builder) { Matcher::Pattern::PatternBuilder.new }

  it '#pattern_of' do
    hole = Matcher::Hole.new(:foo)
    recorder = Matcher::Constant.new(hole).to_recorder > 1
    pattern = builder.pattern_of(recorder)

    expected = Matcher::Expression.build do
      expr(hole) > 1
    end

    assert_kind_of Matcher::Pattern, pattern
    assert_equal expected, pattern.expression
  end
end
