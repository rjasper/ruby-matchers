# frozen_string_literal: true

module Matcher
  class FilterMatcher < Base
    include MappingUtils

    def initialize(filter, matcher, negated: false)
      super()

      @filter = filter
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def ~
      FilterMatcher.new(@filter, @original_matcher, negated: !@negated)
    end

    def check(state)
      actual = state.actual

      unless actual.respond_to?(:each)
        state.errors << state.expected.responding_to(:each) unless @negated
        return
      end

      i = 0
      mapping = {}
      items = []
      failed = false

      actual.each do |act|
        filter_value = @filter.evaluate(
          state.values.merge(actual: act, index: i, original: actual),
        )

        if filter_value
          mapping[items.length] = i
          items << act
        end
      rescue CallError => e
        return nil if @negated

        state.errors[i] << e.message_for_errors(act)
        failed = true
      ensure
        i += 1
      end

      return if failed

      errors = yield(@matcher, items, original: actual)

      state.errors << map_errors(errors) do |nested_error|
        key = nested_error.key

        next unless index_call?(key)

        original_index = mapping[operand_of(key)]

        NestedError.new(index_call_to(original_index), nested_error.child) if original_index
      end
    end

    def to_s
      "#{'~' if @negated}filter(#{@filter}, #{@original_matcher})"
    end

    private

    def mapped_base
      @mapped_base ||= map_base(:filter, @filter)
    end
  end

  module MatcherBuilding
    def filter(expression, matcher = UNDEFINED)
      return Pipe.new { filter(expression, _1) } if
        Matcher.undefined?(matcher)

      expression = expression_of(expression)
      matcher = Matcher.of(matcher)

      FilterMatcher.new(expression, matcher)
    end
  end
end
