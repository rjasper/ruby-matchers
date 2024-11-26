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
        enum = match_node.mapping.path.to_enum(:reverse_each)
        identifiers = []

        loop do
          key = enum.next

          case key
          when :receiver
            identifiers << 0
          when :args
            identifiers << 1
            identifiers << enum.next
          when :kwargs
            identifiers << 2
            identifiers << enum.next
          end
        end

        identifiers << -1

        identifiers
      end

      expressions = match.transform_values(&:expression)

      MessageFactory.new(value_paths, expressions, @block)
    end
  end
end
