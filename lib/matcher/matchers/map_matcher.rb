# frozen_string_literal: true

module Matcher
  class MapMatcher < Base
    include MappingUtils

    def initialize(projection, matcher, negated: false)
      super()

      @projection = projection
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def ~
      MapMatcher.new(@projection, @original_matcher, negated: !@negated)
    end

    def check(state, &)
      return negated_check(state, &) if @negated

      actual = state.actual
      values = state.values

      unless actual.respond_to?(:each)
        state.errors << state.expected.responding_to(:each)
        return
      end

      i = 0
      mapped = []
      mapping_failed = false

      actual.each do |act|
        mapped << @projection.evaluate(
          values.merge(actual: act, index: i, original: actual),
        )
      rescue CallError => e
        state.errors[i] << e.message_for_errors(act)
        mapping_failed = true
      ensure
        i += 1
      end

      return if mapping_failed

      mapped_errors = yield @matcher, mapped, original: actual

      state.errors << map_errors2(mapped_errors)
    end

    def to_s
      "#{'~' if @negated}map(#{@projection}, #{@original_matcher})"
    end

    private

    def negated_check(state)
      actual = state.actual
      values = state.values

      return unless actual.respond_to?(:map)

      mapped = []

      actual.map.with_index do |item, i|
        mapped << @projection.evaluate(
          values.merge(actual: item, index: i, original: actual),
        )
      rescue CallError
        return if @negated
      end

      mapped_errors = yield @matcher, mapped, original: actual

      state.errors << map_errors2(mapped_errors)
    end

    def map_errors2(errors)
      map_errors(errors) do |nested_error|
        key = nested_error.key

        next unless index_call?(key)

        NestedError.new(
          key,
          NestedError.new(@projection, nested_error.child),
        )
      end
    end

    def mapped_base
      @mapped_base ||= map_base(:map, @projection)
    end
  end

  module MatcherBuilding
    def map(expression, matcher = UNDEFINED)
      return Pipe.new { map(expression, _1) } if Matcher.undefined?(matcher)

      expression = expression_of(expression)
      matcher = Matcher.of(matcher)

      MapMatcher.new(expression, matcher)
    end
  end
end
