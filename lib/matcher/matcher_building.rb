# frozen_string_literal: true

module Matcher
  module MatcherBuilding
    def of(matcher)
      Matcher.of(matcher)
    end

    def present(matcher = NULL)
      return Pipe.new { present(_1) } if Matcher.null?(matcher)

      all(value.present?, matcher)
    end
  end
end
