# frozen_string_literal: true

module Matcher
  class MapMatcher < Base
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

      unless actual.respond_to?(:map)
        state.errors << expected.responding_to(:map)
        return
      end

      mapped = []
      mapping_failed = false

      actual.map.with_index do |item, i|
        mapped << @projection.evaluate(
          values.merge(actual: item, index: i, original: actual),
        )
      rescue CallError => e
        state.errors[i] << e.message_for_errors
        mapping_failed = true
      end

      return if mapping_failed

      mapped_errors = yield @matcher, mapped, original: actual

      state.errors << map_errors(mapped_errors, state)
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

      state.errors << map_errors(mapped_errors, state)
    end

    def map_errors(error, state)
      case error
      when EmptyError
        error
      when AndError, OrError
        children = error.children.map { map_errors(_1, state) }
        error.class.new(children)
      when NestedError
        key = error.key

        is_index = key.is_a?(Call) &&
          key.binary? &&
          key.receiver == Variable.actual &&
          (operand = key.args[0]) &&
          operand.is_a?(Constant) &&
          operand.value.is_a?(Integer)

        if is_index
          state.new_collector[key][@projection] << error.child
        else
          error
        end
      when ElementError
        state.new_collector[nested_key] << error
      else
        raise "Unexpected error: #{error.inspect}"
      end
    end

    def nested_key
      proj = @projection
      actual_var = Variable.actual
      as_symbol_proc = proj.is_a?(Call) && proj.unary? && proj.receiver == actual_var
      with_index = proj.variables.include?(:index)

      block = if as_symbol_proc
        SymbolProc.new(proj.method)
      else
        symbol = proj.free_symbol(:e)
        parameters = [[:opt, symbol]]
        parameters << [:opt, :index] if with_index
        expression = proj.substitute(actual: symbol, original: :actual)

        Block.new(parameters, expression)
      end

      if with_index
        map = Call.new(actual_var, :map, [], {})
        Call.new(map, :with_index, [], {}, block)
      else
        Call.new(actual_var, :map, [], {}, block)
      end
    end
  end

  module MatcherBuilding
    def map(expression, matcher = UNDEFINED)
      return Pipe.new { map(expression, _1) } if Matcher.undefined?(matcher)

      expression = Expression.of(expression)
      matcher = Matcher.of(matcher)

      MapMatcher.new(expression, matcher)
    end
  end
end
