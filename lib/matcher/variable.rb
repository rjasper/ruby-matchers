# frozen_string_literal: true

module Matcher
  class Variable < Expression
    attr_reader :symbol

    def initialize(symbol)
      @symbol = symbol
    end

    def variables
      [@symbol]
    end

    def evaluate(values, chain = nil)
      values[@symbol].tap { chain << _1 if chain }
    end

    def ==(other)
      other.instance_of?(Variable) && other.symbol == @symbol
    end
    alias eql? ==

    def hash
      @symbol.hash
    end

    def to_s(substitutions: Expression.default_substitutions)
      substitutions&.[](@symbol) || @symbol.to_s
    end
  end
end
