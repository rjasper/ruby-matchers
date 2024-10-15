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

    def ==(other)
      return true if equal?(other)
      return false unless other.instance_of?(self.class)

      @key.eql?(other.key) &&
        @negated.eql?(other.negated) &&
        @actual.eql?(other.actual) &&
        @args == other.args &&
        @kwargs == other.kwargs
    end

    def eql?(other)
      return true if equal?(other)
      return false unless other.instance_of?(self.class)

      @key.eql?(other.key) &&
        @negated.eql?(other.negated) &&
        @actual.eql?(other.actual) &&
        @args.eql?(other.args) &&
        @kwargs.eql?(other.kwargs)
    end

    def hash
      @hash ||= [@key, @negated, @actual, @args, @kwargs].hash
    end
  end
end
