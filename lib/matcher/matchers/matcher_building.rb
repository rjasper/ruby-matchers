# frozen_string_literal: true

module Matcher
  module MatcherBuilding
    def of(matcher)
      Matcher.of(matcher)
    end

    def neg(matcher)
      ~Matcher.of(matcher)
    end

    def present(matcher)
      AllMatcher.new([
        EqualMatcher.new(nil, negated: true),
        Matcher.of(matcher),
      ])
    end
  end
end
