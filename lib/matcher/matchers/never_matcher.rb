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
      'never'
    end
  end

  module MatcherBuilding
    def never
      NeverMatcher.instance
    end
  end
end
