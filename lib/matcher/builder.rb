# frozen_string_literal: true

module Matcher
  class Builder
    include ExpressionBuilding
    include MatcherBuilding

    def initialize(outside, build_session: Matcher.build_session)
      ExpressionBuilding.init(self, build_session)

      @outside = outside
      @matcher_cache = MatcherCache.current(build_session)
    end

    def matcher_of(value)
      Matcher.of(
        value,
        matcher_cache: @matcher_cache,
        expression_cache: @expression_cache,
      )
    end
    alias of matcher_of

    def outside(&)
      if block_given?
        @outside.instance_eval(&)
      else
        @outside
      end
    end

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
