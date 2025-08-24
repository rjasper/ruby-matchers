# frozen_string_literal: true

module Matcher
  class CaseEqualityMatcher < Base
    def initialize(object, negated: false)
      super()

      @object = object
      @negated = negated
    end

    def ~
      CaseEqualityMatcher.new(@object, negated: !@negated)
    end

    def check(state)
      state.errors << not_equal_message(state) if
        !@negated ^ (@object === state.actual) # rubocop:disable Style/CaseEquality
    end

    def to_s
      if @negated
        "neg(#{@object.inspect})"
      else
        @object.inspect
      end
    end

    private

    def not_equal_message(state)
      case @object
      when Module
        state.expected.not_if(@negated).kind_of(@object)
      when Range
        state.expected.not_if(@negated)
          .between(@object.begin, @object.end, exclude_end: @object.exclude_end?)
      when Regexp
        state.expected.not_if(@negated).matching(@object)
      when Set
        state.expected.not_if(@negated).in(@object)
      else
        state.expected.not_if(@negated).equal(@object)
      end
    end
  end
end
