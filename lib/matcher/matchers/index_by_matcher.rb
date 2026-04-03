# frozen_string_literal: true

module Matcher
  class IndexByMatcher < Base
    include MappingUtils

    def initialize(projection, matcher, negated: false)
      super()

      @projection = projection
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def negate
      IndexByMatcher.new(@projection, @original_matcher, negated: !@negated)
    end

    def validate(state, &)
      return validate_negated(state, &) if @negated

      actual = state.actual

      unless actual.respond_to?(:each)
        state.errors << state.expected.responding_to(:each)
        return
      end

      values = state.values
      failed = false
      index = {}
      mapping = {}
      duplicates = []

      actual.each_with_index do |item, i|
        key = @projection.evaluate(
          values.merge(actual: item, index: i, original: actual),
        )

        mapped_index = mapping[key]

        if mapped_index
          duplicates << [key, i, mapped_index]
        else
          index[key] = item
          mapping[key] = i
        end

        key
      rescue CallError => e
        state.errors[i] << e.message_for_errors(item)
        failed = true
      end

      duplicates.each do |key, i, j|
        state.errors[i] << state.expected(actual[i])
          .not.duplicate_by(@projection, key, j)
      end

      return if failed

      errors = yield(@matcher, index, original: actual)
      errors = map_errors2(errors, mapping) unless state.boolean?

      state.errors << errors
    end

    def to_s
      "#{'~' if @negated}index_by(#{@projection}, #{@original_matcher})"
    end

    private

    def validate_negated(state)
      actual = state.actual

      return unless actual.respond_to?(:each)

      values = state.values
      index = {}
      mapping = {}

      actual.each_with_index do |item, i|
        key = @projection.evaluate(
          values.merge(actual: item, index: i, original: actual),
        )

        return nil if mapping.key?(key)

        index[key] = item
        mapping[key] = i

        key
      rescue CallError
        return nil
      end

      errors = yield(@matcher, index, original: actual)

      state.errors << map_errors2(errors, mapping)
    end

    def map_errors2(error, mapping)
      map_errors(error) do |nested_error|
        key = nested_error.key

        next unless index_call?(key)

        index = mapping[operand_of(key)]

        NestedError.new(index_call_to(index), nested_error.child) if index
      end
    end

    def mapped_base
      return @mapped_base if @mapped_base

      expression = @projection
      with_index = expression.variables.include?(:index)
      element = expression.free_symbol(:e)
      parameters = [[:opt, element]]
      parameters << %i[opt index] if with_index
      substituted = expression.substitute(actual: element, original: :actual)
      pair = ArrayExpression.new([substituted, Variable.new(element)])
      block = Block.new(parameters, pair)

      receiver = if with_index
        Call.new(Variable.actual, :each_with_index)
      else
        Variable.actual
      end

      @mapped_base = Call.new(receiver, :to_h, [], {}, block)
    end
  end

  module MatcherBuilding
    ##
    # Matches against an indexed version of actual.
    #
    # This is really useful when validating an array of items where the order
    # shouldn't matter.
    # @example
    #   # matches:
    #   # [
    #   #   { name: "bar", value: 2 },
    #   #   { name: "foo", value: 1 },
    #   # ]
    #   index_by(_[:name], {
    #     "foo" => { name: "foo", value: 1 },
    #     "bar" => { name: "bar", value: 2 },
    #   })
    #   # alternatively:
    #   index_by(_[:name]) ^ {
    #     "foo" => { name: "foo", value: 1 },
    #     "bar" => { name: "bar", value: 2 },
    #   }
    # @overload index_by(expression, matcher)
    #   @param expression [Expression]
    #   @param matcher [Base]
    #   @return [IndexByMatcher]
    # @overload index_by(expression)
    #   @param expression [Expression]
    #   @return [Chain<IndexByMatcher>]
    def index_by(expression, matcher = UNDEFINED)
      if Matcher.undefined?(matcher)
        return Chain.new { index_by(expression, _1) }
      end

      expression = expression_of(expression)
      matcher = matcher_of(matcher)

      IndexByMatcher.new(expression, matcher)
    end
  end
end
