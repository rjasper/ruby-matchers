# frozen_string_literal: true

module Matcher
  class SetMatcher < Base
    def initialize(array, negated: false)
      super()

      @array = array
      @negated = negated
    end

    def ~
      SetMatcher.new(@array, negated: !@negated)
    end

    def check(state)
      actual = state.actual

      unless actual.is_a?(Array)
        state.errors << state.expected.kind_of(Array) unless @negated
        return
      end

      if @array.length != actual.length
        return if @negated

        state.errors << state.expected.length_of(@array.length, actual.length)
      end

      missing = @array.clone
      extra = []

      actual.each_with_index do |element, i|
        break if missing.empty?

        index = missing.find_index do |m|
          yield(m, element, parent: actual).valid?
        end

        if index
          missing.delete_at(index)
        else
          extra << i
        end
      end

      if @negated
        # when negated then missing.empty? <=> extra.empty?
        state.errors << state.report.namespace(:set).equal(@array) if missing.empty?
      else
        missing.each do |matcher|
          state.errors << state.expected.namespace(:set).including_matchable_by(matcher)
        end

        extra.each do |i|
          state.errors[i] << state.report.including(actual[i])
        end
      end
    end

    def to_s
      "#{'~' if @negated}set(#{@array})"
    end
  end

  module MatcherBuilding
    def set(array)
      SetMatcher.new(array.map { Matcher.of(_1) })
    end
  end

  Matcher::ExpectedPhrasing.instance_exec do
    namespace(:set) do
      define(:including_matchable_by) do |matcher|
        "#{verb} to include an element matching #{matcher} but got #{actual.inspect}"
      end
    end
  end
end
