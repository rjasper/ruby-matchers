# frozen_string_literal: true

module Matcher
  class MessageRule
    def initialize(patterns, block)
      @patterns = patterns
      @block = block
    end

    attr_reader :patterns

    def apply(match)
      expressions = @block.arity >= 2 ? match.expressions : nil

      MessageFactory.new(match.value_paths, expressions, @block)
    end
  end
end
