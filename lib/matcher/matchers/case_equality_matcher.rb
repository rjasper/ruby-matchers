# frozen_string_literal: true

module Matcher
  class CaseEqualityMatcher < Base
    def initialize(object, negated: false)
      super()

      @object = object
      @negated = negated
    end

    def negated
      CaseEqualityMatcher.new(@object, negated: !@negated)
    end

    def check(actual:, **)
      errors << not_equal_message(actual) if !@negated ^ (@object === actual) # rubocop:disable Style/CaseEquality
    end
    protected :check

    def inspect
      if @negated
        "neg(#{@object.inspect})"
      else
        @object.inspect
      end
    end

    private

    def not_equal_message(actual)
      case @object
      when Class
        "expected #{actual.inspect} to be #{ 'not ' if @negated }kind of #{@object}"
      when Range
        "expected #{actual.inspect} to be #{ 'not ' if @negated }within #{@object}"
      when Regexp
        "expected #{actual.inspect} to #{ 'not ' if @negated }match #{@object.inspect}"
      when Set
        "expected #{actual.inspect} to be #{ 'not ' if @negated }member of {#{@object.join(', ')}}"
      else
        if @negated
          "expected #{actual.inspect} to not be #{@object.inspect}"
        else
          "expected #{@object.inspect} but got #{actual.inspect}"
        end
      end
    end
  end
end
