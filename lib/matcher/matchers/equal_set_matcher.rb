# frozen_string_literal: true

module Matcher
  ##
  # Match array elements like a set.
  # @example
  #   m = Matcher.build { equal_set(1, 2, 3) }
  #
  #   m.match?([1, 2, 3]) # => true
  #   m.match?([3, 2, 1]) # => true
  #
  #   m.match([1, 1, 3])
  #   # > root[1]: did not expect duplicate originally at index 0 but got 1
  #   # > root: expected 2 to be included but got [1, 1, 3]
  class EqualSetMatcher < Base
    def initialize(items, negated: false)
      super()

      @items = items
      @negated = negated
      @includes_expressions = items.any?(Expression)
    end

    def negate
      EqualSetMatcher.new(@items, negated: !@negated)
    end

    def validate(state)
      return validate_negated(state) if @negated

      actual = state.actual

      unless actual.respond_to?(:each)
        state.errors << state.expected.responding_to(:each)
        return
      end

      expected_set = item_set(state.values)
      missing = expected_set.dup

      actual.each_with_index do |act, i|
        if expected_set.include?(act)
          unless missing.delete?(act)
            original_index = index_of(actual, act)
            state.errors[i] << state.expected(act).not.duplicate(original_index)
          end
        else
          state.errors[i] << state.expected(act).not.in(state.actual)
        end
      end

      missing.each do |m|
        state.errors << state.expected.including(m)
      end
    end

    def to_s
      "#{'~' if @negated}equal_set(#{@items.join(', ')})"
    end

    private

    def item_set(values)
      if @includes_expressions
        @items.to_set do |item|
          item.is_a?(Expression) ? item.evaluate(values) : item
        end
      else
        @item_set ||= Set.new(@items)
      end
    end

    def validate_negated(state)
      actual = state.actual

      return unless actual.respond_to?(:each)

      expected_set = item_set(state.values)
      missing = expected_set.dup

      actual.each do |act|
        return nil if !expected_set.include?(act) || !missing.delete?(act)
      end

      state.errors << state.expected.namespace(:set).not.equal(@items) if missing.empty?
    end

    def index_of(collection, item)
      collection = collection.enum_for(:each) unless
        collection.respond_to?(:find_index)

      collection.find_index(item)
    end
  end

  module MatcherBuilding
    ##
    # Matches array elements like a set
    # @example
    #   # matches [1, 2, 3] and [3, 2, 1] but neither [0, 1, 2] nor [1, 1, 2, 3]
    #   equal_set(1, 2, 3)
    # @param items [Array]
    # @return [EqualSetMatcher]
    def equal_set(*items)
      items.map! { expression_or_value(_1) }

      EqualSetMatcher.new(items)
    end
  end
end
