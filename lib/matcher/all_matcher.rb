# frozen_string_literal: true

module Matcher
  class AllMatcher < Base
    def initialize(matchers)
      super()

      @matchers = matchers
    end

    def check(actual)
      @matchers.each do |matcher|
        errors << matcher.match(actual)
      end
    end
  end
end
