# frozen_string_literal: true

module Matcher
  class EachMatcher < Base
    def initialize(matcher, index: :index, parent: :parent)
      super()

      @matcher = matcher
      @index = index
      @parent = parent
    end

    def check(actual, **values)
      unless actual.respond_to?(:each)
        errors << "expected to respond to \"each\" but got #{actual.inspect}"
        return
      end

      actual.each_with_index do |item, i|
        errors[i] << @matcher.match(item, **values, @index => i, @parent => actual)
      end
    end

    def inspect
      "each(#{@matcher.inspect})"
    end
  end
end
