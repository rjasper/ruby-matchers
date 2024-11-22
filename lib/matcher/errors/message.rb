# frozen_string_literal: true

module Matcher
  class Message
    attr_reader :key, :negated, :actual, :args, :kwargs

    def initialize(key, negated, actual, *args, **kwargs)
      @key = key
      @negated = negated
      @actual = actual
      @args = args
      @kwargs = kwargs
    end

    def negate!
      @negated = !@negated
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(Message) &&
        @key.eql?(other.key) &&
        @negated == other.negated &&
        @actual.eql?(other.actual) &&
        @args.eql?(other.args) &&
        @kwargs.eql?(other.kwargs)
    end
    alias eql? ==

    def hash
      @hash ||= [@key, @negated, @actual, @args, @kwargs].hash
    end
  end
end
