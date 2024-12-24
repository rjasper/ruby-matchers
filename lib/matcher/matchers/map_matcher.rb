# frozen_string_literal: true

module Matcher
  class MapMatcher < Base
    def initialize(projection, matcher, index: :index, original: :original)
      super()

      @projection = projection
      @matcher = matcher
      @index = index
      @original = original
    end

    def ~
      NegatedMapMatcher.new(@projection, @matcher, index: @index, original: @original)
    end

    def check(actual)
      unless actual.respond_to?(:map)
        errors << expected.responding_to(:map)
        return
      end

      mapped = []
      mapping_failed = false

      actual.map.with_index do |item, i|
        mapped << @projection.evaluate(
          values.merge(actual: item, @index => i, @original => actual),
        )
      rescue CallError => e
        errors[i] << e.message_for_errors
        mapping_failed = true
      end

      return if mapping_failed

      mapped_errors = yield @matcher, mapped, @original => actual

      errors << map_errors(mapped_errors)
    end
    protected :check

    def to_s
      "map(#{@projection}, #{@matcher})"
    end

    module ErrorMapping
      private

      def map_errors(error)
        case error
        when EmptyError
          error
        when AndError, OrError
          children = error.children.map { map_errors(_1) }
          error.class.new(children)
        when NestedError
          key = error.key

          is_index = key.is_a?(Call) &&
            key.binary? &&
            key.receiver == Variable.actual &&
            (operand = key.args[0]) &&
            operand.is_a?(Constant) &&
            operand.constant.is_a?(Integer)

          if is_index
            new_collector[key][@projection] << error.child
          else
            error
          end
        when ElementError
          new_collector[nested_key] << error
        else
          raise "Unexpected error: #{error.inspect}"
        end
      end

      def nested_key
        proj = @projection
        actual_var = Variable.actual
        as_symbol_proc = proj.is_a?(Call) && proj.unary? && proj.receiver == actual_var
        with_index = true if @index && proj.variables.include?(@index)

        block = if as_symbol_proc
          SymbolProc.new(proj.method)
        else
          symbol = find_free_symbol(proj)
          parameters = [[:opt, symbol]]
          parameters << [:opt, @index] if with_index
          expression = proj.substitute(actual: symbol, @original => :actual)

          Block.new(parameters, expression)
        end

        if with_index
          map = Call.new(actual_var, :map, [], {})
          Call.new(map, :with_index, [], {}, block)
        else
          Call.new(actual_var, :map, [], {}, block)
        end
      end

      def find_free_symbol(expression)
        parameters = ExpressionWalker.each_block(expression).flat_map do |block|
          block.parameters.map { |_type, name| name }
        end

        identifiers = (expression.variables + parameters).to_set(&:to_s)

        return :e unless identifiers.include?('e')

        i = 2
        loop do
          name = "e#{i}"

          return name.to_sym unless identifiers.include?(name)

          i += 1
        end
      end
    end

    include ErrorMapping
  end

  module MatcherBuilding
    def map(recorder, matcher = NULL)
      return Pipe.new { map(recorder, _1) } if Matcher.null?(matcher)

      expression = ExpressionRecorder.to_expression(recorder)
      matcher = Matcher.of(matcher)

      MapMatcher.new(expression, matcher)
    end
  end
end
