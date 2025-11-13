# frozen_string_literal: true

module Matcher
  class BooleanMatcher < Base
    BOOLEAN = [false, true].freeze

    def initialize(negated: false)
      @negated = negated
    end

    def negate
      BooleanMatcher.new(negated: !@negated)
    end

    def validate(state)
      state.errors << state.expected.not_if(@negated).in(BOOLEAN) if
        @negated == BOOLEAN.include?(state.actual)
    end

    def to_s
      "#{'~' if @negated}boolean"
    end
  end

  module MatcherBuilding
    ##
    # Matches +true+ and +false+
    # @example
    #   { available: boolean }
    # @return [BooleanMatcher]
    def boolean
      @boolean ||= BooleanMatcher.new
    end
  end
end
