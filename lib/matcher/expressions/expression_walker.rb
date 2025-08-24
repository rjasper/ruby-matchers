# frozen_string_literal: true

module Matcher
  class ExpressionWalker
    attr_accessor :constant_visitor, :variable_visitor, :call_visitor, :block_visitor, :proc_expression_visitor

    def self.each_variable(expression, &block)
      return to_enum(:each_variable, expression) unless block_given?

      walker = new(expression)
      walker.variable_visitor = block
      walker.walk
    end

    def self.each_block(expression, &block)
      return to_enum(:each_block, expression) unless block_given?

      walker = new(expression)
      walker.block_visitor = block
      walker.walk
    end

    def initialize(expression)
      @expression = expression
    end

    def walk
      traverse(@expression)
    end

    private

    def traverse(expression)
      case expression
      when Constant
        @constant_visitor&.call(expression)
      when Variable
        @variable_visitor&.call(expression)
      when Call
        @call_visitor&.call(expression)

        traverse(expression.receiver)
        expression.args.each { traverse(_1) }
        expression.kwargs.each { traverse(_2) }
        traverse_block(expression.block) if expression.block
      when ProcExpression
        @proc_expression_visitor&.call(expression)
      when ArrayExpression, SetExpression
        expression.items.each { traverse(_1) }
      when HashExpression
        expression.pairs.each do |k, v|
          traverse(k)
          traverse(v)
        end
      when RangeExpression
        traverse(expression.begin)
        traverse(expression.end)
      when RescueLastErrorExpression
        traverse(expression.expression)
      else
        raise "unsupported expression type: #{expression.class}"
      end
    end

    def traverse_block(block)
      @block_visitor&.call(block)

      return unless block.is_a?(Block)

      traverse(block.expression)
    end
  end
end
