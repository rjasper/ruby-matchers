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

    def check(actual:, **)
      unless actual.is_a?(Array)
        errors << "expected an Array but got #{actual.inspect}"
        return
      end

      errors << "expected length of #{@array.length} but got #{actual.length}" if
        @array.length != actual.length

      [@array.length, actual.length].min.times do |i|
        errors[i] << @array[i].match(**, actual: actual[i], @index => i, @parent => actual)
      end
    end
    protected :check

    def to_s
      @array.to_s
    end
  end
end
