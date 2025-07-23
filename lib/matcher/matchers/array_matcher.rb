# frozen_string_literal: true

module Matcher
  class ArrayMatcher < Base
    def initialize(array, index: :index, parent: :parent)
      super()

      @array = array
      @index = index
      @parent = parent
    end

    def ~
      NegatedArrayMatcher.new(@array, index: @index, parent: @parent)
    end

    def check(state)
      actual = state.actual
      errors = state.errors

      unless actual.is_a?(Array)
        errors << expected.kind_of(Array)
        return
      end

      errors << expected.length_of(@array.length, actual.length) if @array.length != actual.length

      [@array.length, actual.length].min.times do |i|
        errors[i] << yield(@array[i], actual[i], @index => i, @parent => actual)
      end
    end

    def to_s
      @array.to_s
    end
  end
end
