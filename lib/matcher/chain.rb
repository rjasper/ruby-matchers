# frozen_string_literal: true

module Matcher
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

    def ^(operand)
      if !Recorder.recorder?(operand) && operand.is_a?(Chain)
        Chain.new { @block.call(operand ^ _1) }
      else
        matcher = Matcher.cache(operand)
        result = @block.call(matcher)
        result = ~result if @negated
        result
      end
    end

    def optional(fallback = AlwaysMatcher.instance)
      OptionalChain.new(self, fallback)
    end
  end
end
