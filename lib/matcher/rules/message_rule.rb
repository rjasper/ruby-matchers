# frozen_string_literal: true

module Matcher
  class MessageRule
    def initialize(patterns, block)
      @patterns = patterns
      @block = block
    end

    attr_reader :patterns

    def apply(match)
      value_paths = match.transform_values do |match_node|
        identifiers = match_node.mapping.path.to_a.reverse!
        identifiers << -1
        identifiers
      end

      expressions = match.transform_values(&:expression)

      MessageFactory.new(value_paths, expressions, @block)
    end
  end
end
