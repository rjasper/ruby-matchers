# frozen_string_literal: true

module Matcher
  class AllMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    def &(matcher)
      matcher = Matcher.of(matcher)

      AllMatcher.new(@matchers + [matcher])
    end

    def check(actual, **values)
      @matchers.each do |matcher|
        errors << matcher.match(actual, **values)
      end
    end

    def inspect
      "all(#{@matchers.map(&:inspect).join(', ')})"
    end
  end
end
