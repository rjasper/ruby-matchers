# frozen_string_literal: true

module Matcher
  class IndexByMatcher < Base
    def initialize(projection, matcher, negated: false)
      super()

      @projection = projection
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @negated = negated
    end

    def ~
      IndexByMatcher.new(@projection, @original_matcher, negated: !@negated)
    end

    def check(state, &)
      return negated_check(state, &) if @negated

      actual = state.actual

      unless actual.respond_to?(:each)
        state.errors << expected.responding_to(:each)
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
        state.errors[i] << e.message_for_errors
        failed = true
      end

      duplicates.each do |key, i, j|
        state.errors[i] << expected(actual[i]).not.duplicate_by(@projection, key, j)
      end

      return if failed

      errors = yield(@matcher, index, original: actual)

      state.errors << map_errors(errors, state, mapping)
    end

    def to_s
      "#{'~' if @negated}index_by(#{@projection}, #{@original_matcher})"
    end

    private

    def negated_check(state)
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

      state.errors << map_errors(errors, state, mapping)
    end

    def map_errors(error, state, mapping)
      case error
      when EmptyError
        error
      when AndError, OrError
        children = error.children.map { map_errors(_1, state, mapping) }
        error.class.new(children)
      when NestedError
        key = error.key

        index = key.is_a?(Call) &&
          key.binary? &&
          key.receiver == Variable.actual &&
          (operand = key.args[0]) &&
          operand.is_a?(Constant) &&
          mapping[operand.value]

        if index
          state.new_collector[index] << error.child
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
        parameters << %i[opt index] if with_index
        substitution = proj.substitute(actual: symbol, original: :actual)
        pair = ArrayExpression.new([substitution, Variable.new(symbol)])

        Block.new(parameters, pair)
      end

      map = if with_index
        enum_for_map = Call.new(actual_var, :map)
        Call.new(enum_for_map, :with_index, [], {}, block)
      else
        Call.new(actual_var, :map, [], {}, block)
      end

      Call.new(map, :to_h)
    end
  end

  module MatcherBuilding
    def index_by(expression, matcher = UNDEFINED)
      return Pipe.new { index_by(expression, _1) } if Matcher.undefined?(matcher)

      expression = Expression.of(expression)
      matcher = Matcher.of(matcher)

      IndexByMatcher.new(expression, matcher)
    end
  end
end
