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

    def check(actual)
      return unless actual.respond_to?(:each)

      collector = Errors::Collector.new.or!

      actual.each.with_index do |item, i|
        result = yield @neg_matcher, item, @index => i, @parent => actual

        return if result.valid?

        collector[i] << result
      end

      errors << collector.node
    end
    protected :check

    def to_s
      "~each(#{@matcher})"
    end
  end
end
