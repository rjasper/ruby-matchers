# frozen_string_literal: true

module Matcher
  class NegatedArrayMatcher < Base
    def initialize(array, index: :index, parent: :parent)
      super()

      @array = array
      @neg_array = @array.map(&:~)
      @index = index
      @parent = parent
    end

    def ~
      ArrayMatcher.new(@array, index: @index, parent: @parent)
    end

    def check(state)
      actual = state.actual

      return if !actual.is_a?(Array) || @array.length != actual.length

      collector = state.new_collector.or!

      @array.length.times do |i|
        result = yield @neg_array[i], actual[i], @index => i, @parent => actual

        return if result.valid?

        collector[i] << result
      end

      state.errors << collector.error
    end

    def to_s
      "neg(#{@array})"
    end
  end
end
