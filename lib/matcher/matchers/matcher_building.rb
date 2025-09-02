# frozen_string_literal: true

module Matcher
  module MatcherBuilding
    def neg(matcher)
      ~matcher_of(matcher)
    end

    def present(matcher)
      AllMatcher.new([
        EqualMatcher.new(nil, negated: true),
        matcher_of(matcher),
      ])
    end
  end
end
