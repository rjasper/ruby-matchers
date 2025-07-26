# frozen_string_literal: true

module Matcher
  class BoundVariable < Expression
    def initialize(symbol, value)
      super()

      @symbol = symbol
      @value = value
    end

    attr_reader :symbol, :value

    def variables
      []
    end

    def evaluate(_values)
      @value
    end

    def ==(other)
      other.instance_of?(BoundVariable) &&
        other.symbol == @symbol &&
        other.value == @value
    end
    alias eql? ==

    def hash
      [self.class, @symbol, @value].hash
    end

    def bind(_values)
      self
    end

    def substitute(replacements)
      symbol = replacements[@symbol]
      symbol ? BoundVariable.new(symbol, @value) : self
    end

    def to_s(substitutions: Expression.default_substitutions)
      substitutions&.[](@symbol) || @symbol.to_s
    end
  end
end
