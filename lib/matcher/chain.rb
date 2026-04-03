# frozen_string_literal: true

module Matcher
  ##
  # Matcher helpers like +each+ or +map+ can be chained with the +^+ operator or
  # +chain+ helper. If a helper has the form <tt>my_helper(..., matcher)</tt>
  # then it usually also supports this form <tt>my_helper(...) ^ matcher</tt>.
  # This helps reducing nested parenthesis:
  #
  #   # before
  #   let({ limit: 10 }, map(_.compact, filter(_.even?, _ < vars[:limit])))
  #
  #   # with ^
  #   let(limit: 10) ^
  #     map(_.compact) ^
  #     filter(_.even?) ^
  #     (_ < vars[:limit])
  #
  #   # with chain
  #   chain(
  #     let(limit: 10),
  #     map(_.compact),
  #     filter(_.even?),
  #     _ < vars[:limit],
  #   )
  #
  # Keep operator precedence in mind when working with expressions.
  class Chain
    include NoMatcher
    include NoExpression
    include NoKey

    def initialize(negated: false, &block)
      @block = block
      @negated = negated
    end

    def ~
      Chain.new(negated: !@negated, &@block)
    end

    ##
    # Chains this with a matcher or another chain
    #
    # Many helpers return a Chain that accepts a child matcher via +^+.
    # Chains can also be composed: +each ^ map(_.to_i) ^ (_ > 0)+.
    # @example
    #   each ^ Integer
    #   map(_.to_i) ^ [1, 2]
    #   filter(_.odd?) ^ [1, 3, 5]
    # @param other matcher or chain
    # @return [Base]
    def ^(other)
      if !Recorder.recorder?(other) && other.is_a?(Chain)
        Chain.new { @block.call(other ^ _1) }
      else
        matcher = Matcher.cache(other)
        result = @block.call(matcher)
        result = ~result if @negated
        result
      end
    end

    def optional(fallback = AlwaysMatcher.instance)
      OptionalChain.new(self, fallback)
    end
  end

  module MatcherBuilding
    ##
    # Reduces multiple chains to one
    # @example
    #   chain(let(limit: 10), map(_.compact), filter(_.even?), _ < vars[:limit])
    #   # instead of
    #   let(limit: 10) ^ map(_.compact) ^ filter(_.even?) ^ (_ < vars[:limit])
    #   # which is equivalent to
    #   let({ limit: 10 }, map(_.compact, filter(_.even?, _ < vars[:limit])))
    # @param *chains
    # @return [Chain]
    def chain(*chains)
      chains.reduce(:^)
    end
  end
end
