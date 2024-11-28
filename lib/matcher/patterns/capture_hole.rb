# frozen_string_literal: true

module Matcher
  class CaptureHole < Hole
    def initialize(key, pattern)
      super(key)

      @pattern = pattern
    end

    attr_reader :pattern

    def match?(_expression)
      yield @pattern

      true
    end

    def ==(other)
      super && @pattern == other.pattern
    end
    alias eql? ==

    def to_s
      "capture(#{@key.inspect}, #{@pattern})"
    end
    alias inspect to_s
  end
end
