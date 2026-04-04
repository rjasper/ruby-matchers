# frozen_string_literal: true

module Matcher
  ##
  # == Basic array matching
  #
  #   m = Matcher.build { [1, 2, 3] }
  #
  #   m.match?([1, 2, 3])   # => true
  #   m.match([1, 2])       # > root: expected length of 3 but was 2
  #   m.match([1, 2, 3, 4]) # > root: expected length of 3 but was 4
  #
  #   m.match([3, 2, 1])
  #   # > root[0]: expected 1 but got 3
  #   # > root[2]: expected 3 but got 1
  #
  #   m = Match.build { [Integer, String] }
  #   m.match?([1, "foo"]) # => true
  #
  # == Values passed to element matchers
  # +ArrayMatcher+ passes +index+ and +parent+ to its element matchers.
  #
  #   # index or i
  #   m = Matcher.build { [_ == i] }
  #   m.match?([0]) # => true
  #   m.match([1])  # > root[0]: expected actual == index but got 1 == 0
  #
  #   # parent
  #   m = Matcher.build do
  #     in_order = imply(i > 0, parent[i - 1] <= _)
  #     [in_order, in_order, in_order]
  #   end
  #
  #   m.match?([1, 2, 3])
  #   # => true
  #   m.match([1, 2, 0])
  #   # > root[2]: expected actual >= parent[index - 1] but got 0 >= 2, where
  #   #   parent = [1, 2, 0], index = 2
  class ArrayMatcher < Base
    def initialize(array, negated: false)
      super()

      @array = negated ? array.map(&:~) : array
      @original_array = array
      @negated = negated
    end

    def negate
      ArrayMatcher.new(@original_array, negated: !@negated)
    end

    def validate(state, &)
      return validate_negated(state, &) if @negated

      actual = state.actual
      errors = state.errors

      unless actual.is_a?(Array)
        errors << state.expected.kind_of(Array)
        return
      end

      if @array.length != actual.length
        errors << state.expected.length_of(@array.length, actual.length)
      end

      [@array.length, actual.length].min.times do |i|
        errors[i] << yield(@array[i], actual[i], index: i, parent: actual)
      end
    end

    def to_s
      @negated ? "neg(#{@original_array})" : @original_array.to_s
    end

    private

    def validate_negated(state)
      actual = state.actual

      return if !actual.is_a?(Array) || @array.length != actual.length

      collector = state.new_collector.or!

      @array.length.times do |i|
        result = yield @array[i], actual[i], index: i, parent: actual

        return nil if result.valid?

        collector[i] << result
      end

      state.errors << collector.error
    end
  end
end
