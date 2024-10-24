# frozen_string_literal: true

module Matcher
  class ExpressionMatcher < Base
    attr_reader :expression, :negated

    def initialize(expression, negated: false)
      super()

      @expression = expression
      @negated = negated
    end

    def ~
      ExpressionMatcher.new(@expression, negated: !@negated)
    end

    def check(actual)
      chain = []
      expression_values = values.merge(actual:)
      evaluation = @expression.evaluate(expression_values, chain)

      errors << message_for(expression_values, chain) if @negated != !evaluation
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
      if @expression.is_a?(Call)
        message_for_call(values, chain)
      else
        expected.not_if(@negated).truthy
      end
    end

    def actual_receiver?
      receiver = @expression.receiver
      receiver.is_a?(Variable) && receiver.symbol == :actual
    end

    def operand_constant?(n = 0)
      operand = @expression.args[n]
      !operand.is_a?(Expression) || operand.is_a?(Constant)
    end

    def operand(n = 0)
      operand = @expression.args[n]
      operand.is_a?(Constant) ? operand.constant : operand
    end

    def message_for_call(values, chain)
      if actual_receiver?
        if @expression.binary? && operand_constant?
          operand = @expression.args[0]
          operand = operand.constant if operand.is_a?(Constant)

          case @expression.method
          when :<
            return expected.not_if(@negated).lower_than(operand)
          when :>
            return expected.not_if(@negated).greater_than(operand)
          when :<=
            return expected.not_if(@negated).lower_or_equal_than(operand)
          when :>=
            return expected.not_if(@negated).greater_or_equal_than(operand)
          when :<=>
            # <=> returns nil if operands are uncomparable
            return expected.not_if(@negated).comparable_to(operand)
          when :==
            return expected.not_if(@negated).equal(operand)
          when :!=
            return expected.not_if(@negated).not.equal(operand)
          when :=~
            return expected.not_if(@negated).matching(operand)
          when :!~
            return expected.not_if(@negated).not.matching(operand)
          when :is_a?, :kind_of?
            return expected.not_if(@negated).kind_of(operand)
          when :instance_of?
            return expected.not_if(@negated).instance_of(operand)
          when :respond_to?
            return expected.not_if(@negated).responding_to(operand)
          when :key?
            return expected.not_if(@negated).having_key(operand)
          when :include?
            return expected.not_if(@negated).included_in(operand)
          end
        elsif @expression.method == :! && @expression.unary?
          return expected.not_if(@negated).falsy
        elsif @expression.method == :between? && ternary? && operand_constant?(0) && operand_constant?(1)
          return expected.not_if(@negated).between(operand(0)..operand(1))
        elsif @expression.method.end_with?('?') && @expression.unary?
          return expected.not_if(@negated).predicate(@expression.method)
        end
      end

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
