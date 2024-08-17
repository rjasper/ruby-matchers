# frozen_string_literal: true

module Matcher
  class ExpressionMatcher < Base
    def initialize(expression)
      super()

      @expression = expression
    end

    def check(actual)
      chain = []
      evaluation = @expression.evaluate({ actual: }, chain)

      errors << falsy_message(actual, chain) unless evaluation
    rescue Call::NotRespondingError => e
      errors << e.message_for_errors
    end

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

    def falsy_message(actual, chain)
      if predicate?
        predicate_message(actual, chain)
      else
        regular_message(actual, chain)
      end
    end

    def predicate_message(actual, chain)
      receiver = @expression.receiver&.inspect || 'value'
      arity = @expression.args.length

      string = "expected #{receiver} to "

      string +=
        if arity == 0
          "be #{@expression.method[0...-1]}"
        else # arity == 1
          operand = @expression.args[0].inspect

          "#{operator_word} #{operand}"
        end

      string += " but got #{chain[-2].inspect}" if @expression.method != :!=
      string += " for #{@expression.given_values({ actual: })}" if chain.length > 2

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

    def regular_message(values, chain)
      string = "expected #{@expression.inspect} to be truthy for #{@expression.given_values(values)}"
      string += ", where #{@expression.receiver.inspect} was #{chain[-2].inspect}" if chain.length > 2

      string
    end
  end
end
