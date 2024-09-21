# frozen_string_literal: true

module Matcher
  class NegatedEachMatcher < Base
    def initialize(matcher, index: :index, key: :key, value: :value, parent: :parent)
      super()

      @matcher = matcher
      @neg_matcher = ~matcher
      @index = index
      @key = key
      @value = value
      @parent = parent
    end

    def negated
      EachMatcher.new(
        @matcher,
        index: @index,
        key: @key,
        value: @value,
        parent: @parent,
      )
    end

    def check(actual:, **values)
      return unless actual.respond_to?(:each)

      collector = Errors::Collector.new(true)

      if actual.is_a?(Hash)
        actual.each do |key, value|
          result = @neg_matcher.match(
            **values,
            actual: [key, value],
            @key => key,
            @value => value,
            @parent => actual,
          )

          return if result.valid?

          collector[key] << result
        end
      else
        actual.each.with_index do |item, i|
          result = @neg_matcher.match(**values, actual: item, @index => i, @parent => actual)

          return if result.valid?

          collector[i] << result
        end
      end

      errors << collector.node
    end
    protected :check

    def inspect
      "~each(#{@matcher})"
    end
  end
end
