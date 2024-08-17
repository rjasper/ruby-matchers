# frozen_string_literal: true

module Matcher
  class ArrayMatcher < Base
    def initialize(array, index: :index, parent: :parent)
      super()

      @array = array
      @index = index
      @parent = parent
    end

    def check(actual, **values)
      unless actual.is_a?(Array)
        errors << "expected an Array but got #{actual.inspect}"
        return
      end

      errors << "expected length of #{@array.length} but got #{actual.length}" if
        @array.length != actual.length

      [@array.length, actual.length].min.times do |i|
        errors[i] << @array[i].match(actual[i], **values, @index => i, @parent => actual)
      end
    end

    def inspect
      @array.inspect
    end
  end
end
