# frozen_string_literal: true

module Matcher
  class EachMatcher < Base
    def initialize(matcher)
      super()

      @matcher = matcher
    end

    def check(actual)
      unless actual.respond_to?(:each)
        errors << "expected to respond to \"each\" but got #{actual.inspect}"
        return
      end

      actual.each_with_index do |item, i|
        errors[i] << @matcher.match(item)
      end
    end

    def inspect
      "each(#{@matcher.inspect})"
    end
  end
end
