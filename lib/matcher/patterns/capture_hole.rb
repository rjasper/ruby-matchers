# frozen_string_literal: true

module Matcher
  class CaptureHole < Hole
    def initialize(key, pattern)
      super(key)

      @pattern = pattern
    end

    def match?(_expression)
      yield @pattern

      true
    end

    def to_s
      "capture(#{@key.inspect}, #{@pattern})"
    end
    alias inspect to_s
  end
end
