# frozen_string_literal: true

module Matcher
  class Builder
    def satisfy(message = nil, &block)
      BlockMatcher.new(block, message)
    end

    def equal(value)
      EqualMatcher.new(value)
    end

    def actual
      var(:actual)
    end
    alias _ actual

    def key
      var(:key)
    end
    alias k key

    def value
      var(:value)
    end
    alias v value

    def index
      var(:index)
    end
    alias i index

    def parent
      var(:parent)
    end

    def original
      var(:original)
    end

    def var(symbol)
      variable = Variable.new(symbol)

      ExpressionRecorder.new(variable)
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

    def map(recorder, matcher)
      expression = ExpressionRecorder.to_expression(recorder)
      matcher = Matcher.of(matcher)

      MapMatcher.new(expression, matcher)
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

    def imply(condition, matcher)
      condition = Matcher.of(condition)
      matcher = Matcher.of(matcher)

      ImplyMatcher.new(condition, matcher)
    end

    def imply_one(*matchers)
      ImplyOneMatcher.new(matchers)
    end

    def present(matcher)
      all(value.present?, matcher)
    end

    def iso8601(string_or_time = nil)
      Iso8601Matcher.new(string_or_time)
    end
  end
end
