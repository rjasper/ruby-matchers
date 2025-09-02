# frozen_string_literal: true

module Matcher
  class Optional
    include NoExpression

    CACHEABLE_CLASSES = [
      NilClass,
      FalseClass,
      TrueClass,
      Integer,
      Float,
      Symbol,
      String,
      Regexp,
      Module,
      Base,
    ].freeze

    def self.cache(value, matcher_cache = MatcherCache.current)
      return new(value) if !matcher_cache ||
        !CACHEABLE_CLASSES.include?(value.class) ||
        value.is_a?(String) && !value.frozen?

      (matcher_cache.optionals ||= {})[value] ||= new(value)
    end

    def self.value_of(obj)
      obj.is_a?(Optional) ? obj.value : obj
    end

    def initialize(value)
      @value = value
    end

    attr_reader :value

    def ~
      matcher = Matcher.of(@value)

      OptionalMatcher.new(matcher, negated: true)
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(self.class) && other.value == @value
    end
    alias eql? ==

    def hash
      [self.class, @value].hash
    end

    def to_s
      "optional(#{@value.inspect})"
    end
    alias inspect to_s
  end

  module MatcherBuilding
    def optional(value = UNDEFINED)
      return Pipe.new { optional(_1) } if Matcher.undefined?(value)

      value = Expression.try_recorder(value)

      Optional.new(value)
    end
  end
end
