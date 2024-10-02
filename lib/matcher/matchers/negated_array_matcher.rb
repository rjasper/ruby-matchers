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

    def check(actual:, **)
      return if !actual.is_a?(Array) || @array.length != actual.length

      collector = Errors::Collector.new.or!

      @array.length.times do |i|
        result = @neg_array[i].match(**, actual: actual[i], @index => i, @parent => actual)

        return if result.valid?

        collector[i] << result
      end

      errors << collector.node
    end
    protected :check

    def to_s
      "neg(#{@array})"
    end
  end
end
