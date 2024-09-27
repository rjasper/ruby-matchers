# frozen_string_literal: true

module Matcher
  class ExpressionMatcher < Base
    attr_reader :expression

    def initialize(expression, negated: false)
      super()

      @expression = expression
      @negated = negated
    end

    def negated
      ExpressionMatcher.new(@expression, negated: !@negated)
    end

    def check(**values)
      chain = []
      evaluation = @expression.evaluate(values, chain)

      errors << message_for(values, chain) if @negated != !evaluation
    rescue Call::Error => e
      errors << e.message_for_errors unless @negated
    end
    protected :check

    def to_s
      if @negated
        "neg(#{@expression})"
      else
        @expression.to_s
      end
    end

    private

    BINARY_PREDICATES = %i[== < > <= >= != =~ !~ is_a? kind_of? instance_of?].freeze

    NEGATED_COMPARISONS = {
      :== => :!=,
      :!= => :==,
      :< => :>=,
      :> => :<=,
      :>= => :<,
      :<= => :>,
      :=~ => :!~,
      :!~ => :=~,
    }.freeze

    def predicate?
      method = @expression.method

      (@expression.unary? && method.end_with?('?')) ||
        (@expression.binary? && BINARY_PREDICATES.include?(method))
    end

    def message_for(values, chain)
      if predicate?
        predicate_message(values, chain)
      else
        regular_message(values, chain)
      end
    end

    def predicate_message(values, chain)
      arity = @expression.args.length
      receiver = @expression.receiver
      string = "expected #{receiver.inspect} to "

      if arity == 0
        string += "#{'not ' if @negated}be #{@expression.method[0...-1]}"
      else # arity == 1
        operand = @expression.args[0]

        string += "#{operator_word} #{operand.inspect}"
        string += " (#{operand.evaluate(values).inspect})" if
          operand.is_a?(Call) || operand.is_a?(Variable)
      end

      string += " but got #{chain[-2].inspect}" if
        @expression.method != (@negated ? :== : :!=)

      given = values.dup
      given.delete(receiver.symbol) if receiver.instance_of?(Variable)
      given.delete(operand.symbol) if operand.instance_of?(Variable)
      given_text = @expression.given_values(given)

      string += " for #{given_text}" unless given_text.empty?

      string
    end

    def operator_word
      method = @expression.method
      operator = @negated ? NEGATED_COMPARISONS[method] || method : method

      case operator
      when :kind_of?, :is_a?
        "#{'not ' if @negated}be a kind of"
      when :instance_of?
        "#{'not ' if @negated}be an instance of"
      when :==
        'be'
      when :!=
        'not be'
      when :=~
        'match'
      when :!~
        'not match'
      else
        "be #{operator}"
      end
    end

    def regular_message(values, chain)
      string = "expected #{@expression.inspect} to be #{@negated ? 'falsy' : 'truthy'} for #{@expression.given_values(values)}"
      string += ", where #{@expression.receiver.inspect} was #{chain[-2].inspect}" if chain.length > 2

      string
    end
  end
end
