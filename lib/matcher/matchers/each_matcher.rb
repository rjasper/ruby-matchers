# frozen_string_literal: true

module Matcher
  class EachMatcher < Base
    def initialize(matcher, index: :index, parent: :parent)
      super()

      @matcher = matcher
      @index = index
      @parent = parent
    end

    def ~
      NegatedEachMatcher.new(@matcher, index: @index, parent: @parent)
    end

    def check(actual:, **)
      unless actual.respond_to?(:each)
        errors << "expected to respond to \"each\" but got #{actual.inspect}"
        return
      end

      i = 0
      actual.each do |item|
        errors[i] << @matcher.match(actual: item, **, @index => i, @parent => actual)
        i += 1
      end
    end
    protected :check

    def to_s
      "each(#{@matcher})"
    end
  end
end
