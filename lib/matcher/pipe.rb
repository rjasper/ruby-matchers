# frozen_string_literal: true

module Matcher
  class Pipe
    include NoMatcher
    include NoExpression

    def initialize(negated: false, &block)
      @block = block
      @negated = negated
    end

    def ~
      Pipe.new(negated: !@negated, &@block)
    end

    def ^(operand)
      if !Recorder.recorder?(operand) && operand.is_a?(Pipe)
        Pipe.new { @block.call(operand ^ _1) }
      else
        matcher = Matcher.of(operand)
        result = @block.call(matcher)
        result = ~result if @negated
        result
      end
    end
  end
end
