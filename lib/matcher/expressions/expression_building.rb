# frozen_string_literal: true

module Matcher
  module ExpressionBuilding
    attr_reader :assigns

    def self.init(builder, build_session)
      builder.instance_exec do
        @expression_cache = ExpressionCache.current(build_session)
      end
    end

    def expression_of(value)
      Expression.of(value, expression_cache: @expression_cache)
    end

    def expression_or_value(value)
      Expression.expression_or_value(value, expression_cache: @expression_cache)
    end

    def declare(*symbols, **assigns)
      symbols.concat(assigns.keys - symbols)
      conflicts = symbols & methods

      raise "Cannot declare these variables: #{conflicts.join(', ')}" if conflicts.length > 1
      raise "Cannot declare variable \"#{conflicts[0]}\"" if conflicts.length == 1

      symbols.each do |symbol|
        define_singleton_method(symbol) do
          vars[symbol]
        end
      end

      unless assigns.empty?
        if @assigns
          @assigns.merge!(assigns)
        else
          @assigns = assigns
        end
      end

      UNDEFINED
    end

    def expr(obj = UNDEFINED, &block)
      raise 'obj and block given' if !Matcher.undefined?(obj) && block_given?

      expression = block_given? ? ProcExpression.new(block) : expression_of(obj)
      expression.to_recorder
    end

    def range(from, to, exclude_end = false)
      from = expression_of(from)
      to = expression_of(to)

      RangeExpression.new(from, to, exclude_end)
    end

    def rescue_exception(expression)
      expression = expression_of(expression)
      rescue_last_error = RescueLastErrorExpression.new(expression)

      expression_of(rescue_last_error).to_recorder
    end

    def kernel
      expr(Kernel)
    end

    def concat(*parts)
      parts = parts.map { expression_of(_1) }
      string_expression = StringExpression.new(parts)

      expression_of(string_expression).to_recorder
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

    def pass_through_blocks(arg = UNDEFINED, &)
      # Note that arg might be a recorder where #nil? won't work.

      if Matcher.undefined?(arg)
        Matcher.with_settings(pass_through_blocks: true, &)
      else
        Matcher.with_settings(pass_through_blocks: true) do
          yield arg
        end
      end
    end
    alias ptb pass_through_blocks

    def assign
      value = expression_of(yield)
      call = Call.last_assign

      Call.reset_last_assign

      status = if call&.assignment?
        arg = call.args.last

        if value.is_a?(Constant)
          arg.is_a?(Constant) && value.value.equal?(arg.value)
        else
          value.equal?(arg)
        end
      end

      raise 'Could not return last assignment' unless status

      call.to_recorder
    end

    def vars
      @vars ||= VariableFactory.new(@expression_cache)
    end

    class VariableFactory
      include NoMatcher
      include NoExpression
      include NoKey

      def initialize(expression_cache)
        @expression_cache = expression_cache
      end

      def [](symbol)
        Variable.cache(symbol, expression_cache: @expression_cache).to_recorder
      end
    end
  end
end
