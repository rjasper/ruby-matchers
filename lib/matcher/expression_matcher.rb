# frozen_string_literal: true

module Matcher
  class ExpressionMatcher < Base
    def initialize(expression)
      super()

      @expression = expression
    end

    def check(actual, **values)
      chain = []
      evaluation = @expression.evaluate({ **values, actual: }, chain)

      errors << falsy_message(actual, values, chain) unless evaluation
    rescue Call::NotRespondingError => e
      errors << e.message_for_errors
    end
    protected :check

    def inspect
      @expression.inspect
    end

    private

    BINARY_PREDICATES = %i[== < > <= >= != =~ !~ is_a? kind_of? instance_of?].freeze

    def predicate?
      method = @expression.method

      (@expression.unary? && method.end_with?('?')) ||
        (@expression.binary? && method.in?(BINARY_PREDICATES))
    end

    def falsy_message(actual, values, chain)
      if predicate?
        predicate_message(actual, values, chain)
      else
        regular_message(actual, values, chain)
      end
    end

    def predicate_message(actual, values, chain)
      arity = @expression.args.length
      receiver = @expression.receiver
      string = "expected #{receiver.inspect} to "

      if arity == 0
        string += "be #{@expression.method[0...-1]}"
      else # arity == 1
        operand = @expression.args[0]

        string += "#{operator_word} #{operand.inspect}"
        string += " (#{operand.evaluate({ **values, actual: }).inspect})" if
          operand.is_a?(Call) || operand.is_a?(Variable)
      end

      string += " but got #{chain[-2].inspect}" if @expression.method != :!=

      given = values.merge(actual:)
      given.delete(receiver.symbol) if receiver.instance_of?(Variable)
      given.delete(operand.symbol) if operand.instance_of?(Variable)
      given_text = @expression.given_values(given)

      string += " for #{given_text}" unless given_text.empty?

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
      when :kind_of?, :is_a?
        'be a kind of'
      when :instance_of?
        'be an instance of'
      else
        "be #{@expression.method}"
      end
    end

    def regular_message(actual, values, chain)
      string = "expected #{@expression.inspect} to be truthy for #{@expression.given_values({ **values, actual: })}"
      string += ", where #{@expression.receiver.inspect} was #{chain[-2].inspect}" if chain.length > 2

      string
    end
  end
end
