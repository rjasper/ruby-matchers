# frozen_string_literal: true

module Matcher
  class SetMatcher < Base
    def initialize(array, parent: :parent)
      super()

      @array = array
      @parent = parent
    end

    def check(actual:, **)
      unless actual.is_a?(Array)
        errors << "expected an Array but got #{actual.inspect}"
        return
      end

      errors << "expected length of #{@array.length} but got #{actual.length}" if
        @array.length != actual.length

      missing = @array.clone
      extra = []

      actual.each_with_index do |element, i|
        break if missing.empty?

        index = missing.find_index do |m|
          m.match(**, actual: element, @parent => actual).valid?
        end

        if index
          missing.delete_at(index)
        else
          extra << i
        end
      end

      missing.each { errors << "expected array to include #{_1.inspect}" }
      extra.each { errors[_1] << "unexpected item #{actual[_1].inspect}" }
    end
    protected :check

    def inspect
      "set(#{@array.inspect})"
    end
  end
end
