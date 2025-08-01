# frozen_string_literal: true

module Matcher
  module ExpressionBuilding
    attr_reader :assigns

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

      expression = block_given? ? ProcExpression.new(block) : Expression.of(obj)
      expression.to_recorder
    end

    def kernel
      Constant.new(Kernel).to_recorder
    end

    def concat(*parts)
      parts = parts.map { Expression.of(_1) }

      StringExpression.new(parts).to_recorder
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
      value = Expression.of(yield)
      call = Call.last_assign

      Call.reset_last_assign

      status = if call&.binary?
        arg = call.args[0]

        if value.is_a?(Constant)
          arg.is_a?(Constant) && value.constant.equal?(arg.constant)
        else
          value.equal?(arg)
        end
      end

      raise 'Could not return last assignment' unless status

      call.to_recorder
    end

    def vars
      @vars ||= VariableFactory.new
    end

    class VariableFactory
      include NoMatcher
      include NoExpression

      def initialize
        @cache = {}
      end

      def [](symbol)
        variable = if Variable::WELL_KNOWN.include?(symbol)
          Variable.send(symbol)
        else
          @cache[symbol] ||= Variable.new(symbol)
        end

        variable.to_recorder
      end
    end
  end
end
