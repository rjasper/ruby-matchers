# frozen_string_literal: true

module Matcher
  class TransformRule
    def initialize(patterns, negate, block)
      @patterns = patterns
      @negate = negate
      @block = block
    end

    attr_reader :patterns

    def negate?
      @negate
    end

    def apply(match)
      TransformBuilder.instance.instance_exec(match, &@block)
    end
  end
end
