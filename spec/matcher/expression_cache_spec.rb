# frozen_string_literal: true

require 'test_helper'

module Matcher
  describe ExpressionCache do
    let(:cache) { ExpressionCache.new }

    it 'caches given expressions' do
      one = expression { 1 }
      another = expression { 1 }

      refute_same one, another
      assert_same cache[one], cache[another]
    end

    it 'return well known variables' do
      assert_same Variable.actual, cache[Variable.new(:actual)]
    end

    it '#constant_for' do
      one = cache.constant_for(1)

      assert_kind_of Constant, one
      assert_same one, cache.constant_for(1)
    end

    it '#variable_for' do
      foo = cache.variable_for(:foo)

      assert_kind_of Variable, foo
      assert_same foo, cache.variable_for(:foo)
    end

    it '#variable_for: well known' do
      assert_same Variable.actual, cache.variable_for(:actual)
    end
  end
end
