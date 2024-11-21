# frozen_string_literal: true

module Matcher
  class ExpressionWalker
    attr_accessor :constant_visitor, :variable_visitor, :call_visitor, :block_visitor, :block_expression_visitor

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
        @block_expression_visitor&.call(expression)
      end
    end

    def traverse_block(block)
      @block_expression_visitor&.call(block)

      return unless block.is_a?(Block)

      traverse(block.expression)
    end
  end
end
