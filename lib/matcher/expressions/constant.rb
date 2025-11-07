# frozen_string_literal: true

module Matcher
  class Constant < Expression
    def self.cache(value, expression_cache = ExpressionCache.current)
      if expression_cache
        expression_cache.constant_for(value)
      else
        Constant.new(value)
      end
    end

    attr_reader :value

    def initialize(value)
      super()

      @value = value
    end

    def negated
      Constant.new(!@value)
    end

    def variables
      []
    end

    def evaluate(_values)
      @value
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(Constant) &&
        @value.eql?(other.value)
    end
    alias eql? ==

    def hash
      @hash ||= [self.class, @value].hash
    end

    def substitute(_replacements)
      self
    end

    def to_s(substitutions: nil)
      @value.inspect
    end
  end
end
