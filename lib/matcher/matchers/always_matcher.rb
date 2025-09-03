# frozen_string_literal: true

module Matcher
  class AlwaysMatcher < Base
    include Singleton

    def ~
      NeverMatcher.instance
    end

    def check(_state) end

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
