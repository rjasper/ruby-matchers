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
  end
end
