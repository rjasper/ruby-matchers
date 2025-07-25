# frozen_string_literal: true

module Matcher
  module MatcherBuilding
    def of(matcher)
      Matcher.of(matcher)
    end

    def present(matcher = UNDEFINED)
      return Pipe.new { present(_1) } if Matcher.undefined?(matcher)

      all(!_.nil?, matcher)
    end
  end
end
