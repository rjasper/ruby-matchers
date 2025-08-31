# frozen_string_literal: true

require 'test_helper'

describe Matcher::Pattern do
  it '::build' do
    pattern = Matcher::Pattern.build { hole(:foo) > 1 }

    expected = Matcher::Expression.build do
      expr(Matcher::Hole.new(:foo)) > 1
    end

    assert_equal expected, pattern.expression
  end
end
