# frozen_string_literal: true

module Matcher
  class Builder
    def satisfy(message = nil, &block)
      BlockMatcher.new(block, message)
    end

    def value
      ExpressionRecorder.new
    end

    def all_entries(hash)
      Matcher.with_settings(all_entries: true) do
        Matcher.of(hash)
      end
    end

    def partial_entries(hash)
      Matcher.with_settings(all_entries: false) do
        Matcher.of(hash)
      end
    end

    def all(*matchers)
      AllMatcher.new(matchers.map { Matcher.of(_1) })
    end

    def any(*matchers)
      AnyMatcher.new(matchers.map { Matcher.of(_1) })
    end
  end
end
