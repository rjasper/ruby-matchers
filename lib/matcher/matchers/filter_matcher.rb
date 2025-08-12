# frozen_string_literal: true

module Matcher
  class FilterMatcher < Base
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
        state.errors << expected.responding_to(:each) unless @negated
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

        state.errors[i] << e.message_for_errors
        failed = true
      ensure
        i += 1
      end

      return if failed

      errors = yield(@matcher, items, original: actual)

      state.errors << map_errors(errors, state, mapping)
    end

    def to_s
      "#{'~' if @negated}filter(#{@filter}, #{@original_matcher})"
    end

    private

    def map_errors(error, state, mapping)
      case error
      when EmptyError
        error
      when AndError, OrError
        children = error.children.map { map_errors(_1, state, mapping) }
        error.class.new(children)
      when NestedError
        key = error.key

        mapped_index = key.is_a?(Call) &&
          key.binary? &&
          key.receiver == Variable.actual &&
          (operand = key.args[0]) &&
          operand.is_a?(Constant) &&
          operand.value

        if mapped_index.is_a?(Integer) && (original_index = mapping[mapped_index])
          state.new_collector[original_index] << error.child
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
      proj = @filter
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
        filter = Call.new(actual_var, :filter, [], {})
        Call.new(filter, :with_index, [], {}, block)
      else
        Call.new(actual_var, :filter, [], {}, block)
      end
    end
  end

  module MatcherBuilding
    def filter(expression, matcher = UNDEFINED)
      return Pipe.new { filter(expression, _1) } if
        Matcher.undefined?(matcher)

      expression = Expression.of(expression)
      matcher = Matcher.of(matcher)

      FilterMatcher.new(expression, matcher)
    end
  end
end
