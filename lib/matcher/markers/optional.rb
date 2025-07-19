# frozen_string_literal: true

module Matcher
  class Optional
    def self.value_of(obj)
      obj.is_a?(Optional) ? obj.value : obj
    end

    def initialize(value)
      @value = value
    end

    attr_reader :value

    def ==(other)
      return true if equal?(other)

      other.instance_of?(self.class) && other.value == @value
    end
    alias eql? ==

    def hash
      @hash ||= [Optional, @value].hash
    end

    def to_s
      "optional(#{@value.inspect})"
    end
    alias inspect to_s
  end

  module MatcherBuilding
    def optional(value)
      value = Expression.try_recorder(value)

      Optional.new(value)
    end
  end
end
