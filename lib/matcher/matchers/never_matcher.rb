# frozen_string_literal: true

module Matcher
  class NeverMatcher < Base
    include Singleton

    def &(matcher)
      self
    end

    def |(matcher)
      matcher
    end

    def ~
      AlwaysMatcher.instance
    end

    def check(state)
      state.errors << report.exist
    end

    def to_s
      'never'
    end
  end

  module MatcherBuilding
    def never
      NeverMatcher.instance
    end
  end
end
