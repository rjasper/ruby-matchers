# frozen_string_literal: true

module Matcher
  class ExpressionMatcher < Base
    def initialize(expression)
      super()

      @expression = expression
    end

    def check(actual)
      chain = []
      evaluation = @expression.evaluate(actual, chain)

      errors << falsy_message(actual, chain) unless evaluation
    rescue Expression::NotRespondingError => e
      errors << not_responding_message(e)
    end

    private

    def falsy_message(actual, chain)
      return comparison_message(actual, chain) if @expression.comparison?

      string = "expected #{@expression.inspect} to be truthy for value = #{actual.inspect}"
      string += ", where #{@expression.receiver.inspect} was #{chain[-2].inspect}" if chain.length > 2

      string
    end

    def comparison_message(actual, chain)
      receiver = @expression.receiver&.inspect || 'value'
      operand = @expression.args[0].inspect

      string = "expected #{receiver} to #{operator_word} #{operand}"
      string += " but got #{chain[-2].inspect}" if @expression.method != :!=
      string += " for value = #{actual.inspect}"

      string
    end

    def operator_word
      case @expression.method
      when :==
        'be'
      when :!=
        'not be'
      when :=~
        'match'
      when :!~
        'not match'
      else
        "be #{@expression.method}"
      end
    end

    def not_responding_message(exception)
      expression = exception.expression.receiver.inspect
      method = exception.expression.method
      actual = exception.receiver.inspect
      value = exception.value.inspect

      "expected #{expression} to respond to #{method} but got #{actual} where value = #{value}"
    end
  end
end
