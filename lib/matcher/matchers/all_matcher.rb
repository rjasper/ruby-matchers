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

    def negated
      AnyMatcher.new(@matchers.map(&:~))
    end

    def check(**)
      @matchers.each do |matcher|
        errors << matcher.match(**)
      end
    end
    protected :check

    def inspect
      "all(#{@matchers.map(&:inspect).join(', ')})"
    end
  end
end
