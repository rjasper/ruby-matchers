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

    def each(matcher)
      EachMatcher.new(Matcher.of(matcher))
    end

    def set(array)
      SetMatcher.new(array.map { Matcher.of(_1) })
    end

    def all(*matchers)
      AllMatcher.new(matchers.map { Matcher.of(_1) })
    end

    def any(*matchers)
      AnyMatcher.new(matchers.map { Matcher.of(_1) })
    end

    def present(matcher)
      all(value.present?, matcher)
    end

    def iso8601(string_or_time = nil)
      Iso8601Matcher.new(string_or_time)
    end
  end
end
