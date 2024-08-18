# frozen_string_literal: true

module Matcher
  class Builder
    delegate :of, to: :Matcher

    def satisfy(message = nil, &block)
      BlockMatcher.new(block, message)
    end

    def equal(value)
      EqualMatcher.new(value)
    end

    def actual
      vars[:actual]
    end
    alias _ actual

    def key
      vars[:key]
    end
    alias k key

    def value
      vars[:value]
    end
    alias v value

    def index
      vars[:index]
    end
    alias i index

    def parent
      vars[:parent]
    end

    def original
      vars[:original]
    end

    def logical_operators(&)
      Matcher.with_settings(logical_operators: true, &)
    end
    alias lo logical_operators

    def vars
      VariableFactory.instance
    end

    class VariableFactory
      include Singleton

      def [](symbol)
        variable = Variable.new(symbol)

        ExpressionRecorder.new(variable)
      end
    end

    def setvar(assigns, matcher)
      matcher = Matcher.of(matcher)

      SetVariablesMatcher.new(assigns, matcher)
    end

    def refs?
      !@refs.nil?
    end

    def refs
      @refs ||= ReferenceCollection.new
    end

    class ReferenceCollection
      attr_reader :last_object_id, :last_matcher

      def initialize
        @targets = {}
        @last_object_id = nil
        @last_matcher = nil
      end

      def [](key, cyclic: false)
        ReferenceMatcher.new(@targets, key, cyclic:)
      end

      def []=(key, matcher)
        raise "Cannot reassign reference: #{key.inspect}" if @targets.key?(key)

        @last_object_id = matcher.object_id
        matcher = Matcher.of(matcher)
        @last_matcher = matcher
        @targets[key] = matcher
      end
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
