# frozen_string_literal: true

module Matcher
  class NegatedMapMatcher < Base
    def initialize(projection, matcher, index: :index, original: :original)
      super()

      @projection = projection
      @matcher = matcher
      @neg_matcher = ~matcher
      @index = index
      @original = original
    end

    def ~
      MapMatcher.new(@projection, @matcher, index: @index, original: @original)
    end

    def check(actual:, **values)
      return unless actual.respond_to?(:map)

      mapped = []

      actual.map.with_index do |item, i|
        mapped << @projection.evaluate({
          **values,
          actual: item,
          @index => i,
          @original => actual,
        })
      rescue Call::Error
        return if @negated
      end

      mapped_errors = @neg_matcher.match(**values, actual: mapped, @original => actual)

      errors << MapMatcher.map_errors(mapped_errors, @projection)
    end
    protected :check

    def to_s
      "~map(#{@projection}, #{@matcher})"
    end
  end
end
