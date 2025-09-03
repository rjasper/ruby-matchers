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

  it '::build: caches expressions' do
    pattern = Matcher::Pattern.build do
      [const(:foo), const(:foo)]
    end

    foo1, foo2 = pattern.expression.items

    assert_same foo1, foo2
  end
end
