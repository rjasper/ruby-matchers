# frozen_string_literal: true

module Matcher
  class ArrayMatcher < Base
    def initialize(array)
      super()

      @array = array
    end

    def negate
      NegatedArrayMatcher.new(@array)
    end

    def check(state)
      actual = state.actual
      errors = state.errors

      unless actual.is_a?(Array)
        errors << state.expected.kind_of(Array)
        return
      end

      errors << state.expected.length_of(@array.length, actual.length) if @array.length != actual.length

      [@array.length, actual.length].min.times do |i|
        errors[i] << yield(@array[i], actual[i], index: i, parent: actual)
      end
    end

    def to_s
      @array.to_s
    end
  end
end
