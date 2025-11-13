# frozen_string_literal: true

module Matcher
  ##
  # Map items to another value before matching.
  # @example
  #   m = Matcher.build { map(_.to_i, [1, 2]) } # OR
  #   m = Matcher.build { map(_.to_i) ^ [1, 2] }
  #
  #   m.match?(["1", "2"])
  #   # => true
  #   m.match(["1", :foo])
  #   # > root[1]: expected an object responding to 'to_i' but got :foo
  #   m.match(["1", "3"])
  #   # > root[1].to_i: expected 2 but got 3
  #
  #   m = Matcher.build { map(_.to_i, _.sum == 3) }
  #   m.match?(["1", "2"])
  #   # => true
  #   m.match(["1", "2", "3"])
  #   # > root.map(&:to_i): expected actual.sum == 3 but got 6 == 3, where actual = [1, 2, 3]
  class MapMatcher < Base
    include MappingUtils

    def initialize(projection, matcher, negated: false)
      super()

      @projection = projection
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def negate
      MapMatcher.new(@projection, @original_matcher, negated: !@negated)
    end

    def validate(state, &)
      return validate_negated(state, &) if @negated

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

      errors = yield @matcher, mapped, original: actual
      errors = map_errors2(errors) unless state.boolean?

      state.errors << errors
    end

    def to_s
      "#{'~' if @negated}map(#{@projection}, #{@original_matcher})"
    end

    private

    def validate_negated(state)
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
    ##
    # Maps items to another value before matching
    # == +expression+ values
    # - actual
    # - index
    # - original
    # == +matcher+ values
    # - original
    # @example
    #   # matches ["1", "2"]
    #   map(_.to_i, [1, 2])
    #   # alternatively:
    #   map(_.to_i) ^ [1, 2]
    # @overload map(expression, matcher)
    #   @param expression [Expression]
    #   @param matcher [Base]
    #   @return [MapMatcher]
    # @overload map(expression)
    #   @param expression [Expression]
    #   @return [Chain<MapMatcher>]
    def map(expression, matcher = UNDEFINED)
      return Chain.new { map(expression, _1) } if Matcher.undefined?(matcher)

      expression = expression_of(expression)
      matcher = matcher_of(matcher)

      MapMatcher.new(expression, matcher)
    end
  end
end
