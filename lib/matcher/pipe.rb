# frozen_string_literal: true

module Matcher
  class Pipe
    include NoMatcher
    include NoExpression

    def initialize(&block)
      @block = block
    end

    def ^(operand)
      if !ExpressionRecorder.recorder?(operand) && operand.is_a?(Pipe)
        Pipe.new { @block.call(operand ^ _1) }
      else
        matcher = Matcher.of(operand)
        @block.call(matcher)
      end
    end
  end
end
