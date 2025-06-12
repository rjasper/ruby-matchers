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

    def check(_actual)
      errors << report.existing_index
    end
    protected :check

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
