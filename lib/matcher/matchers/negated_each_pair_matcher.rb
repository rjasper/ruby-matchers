# frozen_string_literal: true

module Matcher
  class NegatedEachPairMatcher < Base
    def initialize(matcher, key: :key, value: :value, parent: :parent)
      super()

      @matcher = matcher
      @neg_matcher = ~matcher
      @key = key
      @value = value
      @parent = parent
    end

    def ~
      EachPairMatcher.new(@matcher, key: @key, value: @value, parent: @parent)
    end

    def check(actual)
      return unless actual.respond_to?(:each_pair)

      collector = Errors::Collector.new.or!

      actual.each do |key, value|
        result = yield @neg_matcher, [key, value], @key => key, @value => value, @parent => actual

        return if result.valid?

        collector[key] << result
      end

      errors << collector.node
    end
    protected :check

    def to_s
      "~each_pair(#{@matcher})"
    end
  end
end
