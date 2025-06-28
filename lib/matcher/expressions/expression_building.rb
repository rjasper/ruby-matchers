# frozen_string_literal: true

module Matcher
  module ExpressionBuilding
    def declare(*symbols)
      conflicts = symbols & methods

      raise "Cannot declare these variables: #{conflicts.join(', ')}" if conflicts.length > 1
      raise "Cannot declare variable \"#{conflicts[0]}\"" if conflicts.length == 1

      symbols.each do |symbol|
        define_singleton_method(symbol) do
          vars[symbol]
        end
      end
    end

    def expr(constant = NULL, &block)
      raise "constant and block given" if !Matcher.null?(constant) && block_given?

      expression = if block_given?
        ProcExpression.new(block)
      else
        Constant.new(constant)
      end

      expression.to_recorder
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

    def pass_through_blocks(arg = NULL, &)
      # Note that arg might be a recorder where #nil? won't work.

      if Matcher.null?(arg)
        Matcher.with_settings(pass_through_blocks: true, &)
      else
        Matcher.with_settings(pass_through_blocks: true) do
          yield arg
        end
      end

    end
    alias ptb pass_through_blocks

    def assign
      value = ExpressionRecorder.transform(yield)
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
