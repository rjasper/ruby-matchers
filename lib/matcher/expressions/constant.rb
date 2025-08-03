# frozen_string_literal: true

module Matcher
  class Constant < Expression
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
      [self.class, @value].hash
    end

    def substitute(_replacements)
      self
    end

    def to_s(substitutions: nil)
      @value.inspect
    end
  end
end
