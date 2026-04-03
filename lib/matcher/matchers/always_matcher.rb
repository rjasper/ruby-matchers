# frozen_string_literal: true

module Matcher
  class AlwaysMatcher < Base
    include Singleton

    def ~
      NeverMatcher.instance
    end

    def validate(_state) end

    def to_s
      "always"
    end
  end

  module MatcherDsl
    ##
    # Matches always
    #
    # Many matchers accept child matchers, for instance the HashMatcher. But
    # before they invoke a child matcher they often perform implicit checks. And
    # sometimes, we are only interested in those implicit checks and don't care
    # about having a child matcher.
    #
    # @example
    #   { foo: always }
    # @return [AlwaysMatcher]
    def always
      AlwaysMatcher.instance
    end
  end
end
