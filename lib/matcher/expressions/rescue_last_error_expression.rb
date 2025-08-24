# frozen_string_literal: true

module Matcher
  class RescueLastErrorExpression < Expression
    extend Forwardable

    def initialize(expression)
      super()

      @expression = expression
    end

    attr_reader :expression

    def_delegator :@expression, :variables

    def ==(other)
      equal?(other) ||
        other.instance_of?(self.class) &&
        @expression == other.expression
    end
    alias eql? ==

    def hash
      [self.class, @expression].hash
    end

    def evaluate(values)
      @expression.evaluate(values)
    rescue CallError => e
      e.cause
    end

    def substitute(replacements)
      substitution = @expression.substitute(replacements)

      RescueLastErrorExpression.new(substitution)
    end

    def to_s(**)
      "#{@expression.to_s(**)} rescue $!"
    end
  end
end
