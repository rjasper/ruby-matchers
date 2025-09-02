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

    def self.well_known?(symbol)
      WELL_KNOWN.include?(symbol)
    end

    def self.cache(symbol, expression_cache: true)
      return send(symbol) if well_known?(symbol)

      expression_cache = ExpressionCache.current if expression_cache == true

      if expression_cache
        expression_cache.less_known_variable_for(symbol)
      else
        new(symbol)
      end
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
      [self.class, @symbol].hash
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
