# frozen_string_literal: true

module Matcher
  class RuleSet
    Rule = Struct.new(:patterns, :block)

    module RuleBuilding
      def transform(*patterns, &block)
        patterns.map! { Pattern.of(_1) }
        @rules << TransformRule.new(patterns, block)

        nil
      end

      def message(*patterns, &block)
        patterns.map! { Pattern.of(_1) }
        @rules << MessageRule.new(patterns, block)

        nil
      end
    end

    class RuleBuilder
      include PatternBuilding
      include RuleBuilding

      def initialize(rules = [])
        @rules = rules
      end

      attr_reader :rules
    end

    module Definition
      def self.included(base)
        base.instance_exec do
          extend PatternBuilding
          extend RuleBuilding

          @rules = []

          class << self
            attr_reader :rules
          end
        end
      end
    end

    class TransformRule
      def initialize(patterns, block)
        @patterns = patterns
        @block = block
      end

      attr_reader :patterns

      def apply(match)
        TransformBuilder.instance.instance_exec(match, &@block)
      end
    end

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

    class MessageFactory
      def initialize(value_paths, expressions, block)
        @value_paths = value_paths
        @expressions = expressions
        @block = block
      end

      def create(matcher, value_tree)
        values = @value_paths.transform_values { _1.reduce(value_tree, :[]) }

        matcher.instance_exec(values, @expressions, &@block)
      end
    end

    def initialize(rules = [], &)
      @rules = rules

      configure(&) if block_given?
    end

    def configure(&)
      builder = RuleBuilder.new(@rules)
      builder.instance_exec(&)

      self
    end

    def apply(expression)
      cur = expression
      mapping = AstMapping.new
      result = nil

      while (rule, match = find_rule(cur, mapping))
        result = rule.apply(match)

        return result unless rule.is_a?(TransformRule)

        cur = result.expression
        mapping = result.mapping
      end

      result
    end

    TransformMapping = Struct.new(:path, :receiver, :args, :kwargs)

    class TransformBuilder
      include Singleton

      def call(match, receiver, method, *args, **kwargs)
        expression = Call.new(
          receiver.expression,
          method,
          args.map(&:expression),
          kwargs.transform_values(&:expression),
        )

        mapping = TransformMapping.new
        mapping.path = match.mapping.path
        mapping.receiver = receiver.mapping
        mapping.args = args.map(&:mapping)
        mapping.kwargs = kwargs.transform_values(&:mapping)

        Pattern::MatchNode.new(expression, mapping)
      end
    end

    private

    def find_rule(expression, mapping)
      @rules.each do |rule|
        rule.patterns.each do |pattern|
          match = pattern.match(expression, mapping)

          return [rule, match] if match
        end
      end

      nil
    end
  end
end
