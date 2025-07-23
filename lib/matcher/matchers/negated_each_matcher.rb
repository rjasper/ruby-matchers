# frozen_string_literal: true

module Matcher
  class NegatedEachMatcher < Base
    def initialize(matcher, index: :index, parent: :parent)
      super()

      @matcher = matcher
      @neg_matcher = ~matcher
      @index = index
      @parent = parent
    end

    def ~
      EachMatcher.new(@matcher, index: @index, parent: @parent)
    end

    def check(state)
      return unless state.actual.respond_to?(:each)

      collector = state.new_collector.or!

      state.actual.each.with_index do |item, i|
        result = yield @neg_matcher, item, @index => i, @parent => state.actual

        return if result.valid?

        collector[i] << result
      end

      state.errors << collector.error
    end

    def to_s
      "~each(#{@matcher})"
    end
  end
end
