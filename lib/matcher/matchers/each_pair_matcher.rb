# frozen_string_literal: true

module Matcher
  class EachPairMatcher < Base
    def initialize(matcher, key: :key, value: :value, parent: :parent)
      super()

      @matcher = matcher
      @key = key
      @value = value
      @parent = parent
    end

    def ~
      NegatedEachPairMatcher.new(@matcher, key: @key, value: @value, parent: @parent)
    end

    def check(actual:, **)
      unless actual.respond_to?(:each_pair)
        errors << "expected to respond to \"each_pair\" but got #{actual.inspect}"
        return
      end

      actual.each_pair do |key, value|
        errors[key] << @matcher.match(
          **,
          actual: [key, value],
          @key => key,
          @value => value,
          @parent => actual,
        )
      end
    end
    protected :check

    def to_s
      "each_pair(#{@matcher})"
    end
  end
end
