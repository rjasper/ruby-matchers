# frozen_string_literal: true

module Matcher
  class NeverMatcher < Base
    include Singleton

    def ~
      AlwaysMatcher.instance
    end

    def validate(state)
      state.errors << state.report.exist
    end

    def to_s
      "never"
    end
  end

  module MatcherBuilding
    ##
    # Never matches. Opposite of {#always}
    #
    # Where is the use-case for +never+? Can't think of one other than it's
    # +~always+, and we really want to be able to negate matchers. Some matchers
    # check whether their child matcher is a NeverMatcher to provide a fitting
    # error message.
    #
    # @return [NeverMatcher]
    # @see #always
    def never
      NeverMatcher.instance
    end
  end
end
