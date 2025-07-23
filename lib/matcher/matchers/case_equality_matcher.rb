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
      state.errors << not_equal_message if
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

    def not_equal_message
      case @object
      when Module
        expected.not_if(@negated).kind_of(@object)
      when Range
        expected.not_if(@negated).between(@object.begin, @object.end, @object.exclude_end?)
      when Regexp
        expected.not_if(@negated).matching(@object)
      when Set
        expected.not_if(@negated).in(@object)
      else
        expected.not_if(@negated).equal(@object)
      end
    end
  end
end
