# frozen_string_literal: true

module Matcher
  class Variable < Expression
    WELL_KNOWN = %i[actual key value index parent original].freeze

    WELL_KNOWN.each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{method}                                                      # def self.actual
          @#{method} ||= Variable.new(:#{method})                               #   @actual ||= Variable.actual
        end                                                                     # end
      RUBY
    end

    attr_reader :symbol

    def initialize(symbol)
      super()

      @symbol = symbol
    end

    def variables
      [@symbol]
    end

    def evaluate(values)
      value = values[@symbol]

      raise "no value for #{@symbol.inspect}" if value.nil? && !values.key?(@symbol)

      value
    end

    def ==(other)
      other.instance_of?(Variable) && other.symbol == @symbol
    end
    alias eql? ==

    def hash
      @symbol.hash
    end

    def bind(values)
      value = values[@symbol]

      if !value.nil? || values.key?(@symbol)
        BoundVariable.new(@symbol, value)
      else
        self
      end
    end

    def substitute(replacements)
      symbol = replacements[@symbol]
      symbol ? Variable.new(symbol) : self
    end

    def to_s(substitutions: Expression.default_substitutions)
      substitutions&.[](@symbol) || @symbol.to_s
    end
  end
end
