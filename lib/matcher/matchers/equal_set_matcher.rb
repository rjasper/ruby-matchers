# frozen_string_literal: true

module Matcher
  class EqualSetMatcher < Base
    def initialize(items, negated: false)
      super()

      @items = items
      @negated = negated
      @includes_expressions = items.any? { _1.is_a?(Expression) }
    end

    def negate
      EqualSetMatcher.new(@items, negated: !@negated)
    end

    def set_for(values)
      if @includes_expressions
        @items.to_set do |item|
          item.is_a?(Expression) ? item.evalute(values) : item
        end
      else
        @set ||= Set.new(@items)
      end
    end

    def validate(state)
      return negated_check(state) if @negated

      actual = state.actual

      unless actual.respond_to?(:each)
        state.errors << state.expected.responding_to(:each)
        return
      end

      expected_set = set_for(state.values)
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
      "#{'~' if @negated}equal_set(#{@items.map(&:to_s).join(', ')})"
    end

    private

    def negated_check(state)
      actual = state.actual

      return unless actual.respond_to?(:each)

      expected_set = set_for(state.values)
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
    def equal_set(*items)
      items.map! { expression_or_value(_1) }

      EqualSetMatcher.new(items)
    end
  end
end
