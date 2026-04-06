# frozen_string_literal: true

module Matcher
  class OptionalChain
    include NoExpression
    include NoKey
    extend Forwardable

    def initialize(chain, fallback)
      @chain = chain
      @fallback = fallback
    end

    def_delegator :@chain, :^

    def ~
      OptionalChain.new(~@chain, @fallback)
    end

    def +(other)
      Matcher.cache(fallback) + other
    end

    def *(other)
      Matcher.cache(fallback) * other
    end

    def |(other)
      Matcher.cache(fallback) | other
    end

    def &(other)
      Matcher.cache(fallback) & other
    end

    def >>(other)
      Matcher.cache(fallback) >> other
    end

    def fallback
      @chain ^ @fallback
    end
  end
end
