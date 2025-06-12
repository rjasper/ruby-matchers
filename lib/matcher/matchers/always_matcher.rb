# frozen_string_literal: true

module Matcher
  class AlwaysMatcher < Base
    include Singleton

    def &(matcher)
      matcher
    end

    def |(matcher)
      matcher
    end

    def ~
      NeverMatcher.instance
    end

    def check(_actual); end
    protected :check

    def to_s
      'always'
    end
  end

  module MatcherBuilding
    def always
      AlwaysMatcher.instance
    end
  end
end
