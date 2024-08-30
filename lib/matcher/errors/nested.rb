# frozen_string_literal: true

module Matcher
  module Errors
    class Nested < Node
      def self.from(key, node)
        return node if node.is_a?(Empty)

        normalize_key(key)
          .reverse_each
          .reduce(node) { Nested.new(_2, _1) }
      end

      def self.normalize_key(key)
        return [key] unless key.is_a?(Expression)

        keys = []
        expression = key

        while expression.instance_of?(Call)
          unless expression.variables.include?(:actual)
            keys.unshift(expression)
            break
          end

          key = if expression.method == :[] && expression.binary?
            expression.args[0]
          else
            variable = Variable.new(:actual)
            expression.new_root(variable)
          end

          keys.unshift(key)
          expression = expression.receiver
        end

        keys
      end

      attr_reader :key, :node

      def initialize(key, node)
        @key = key
        @node = node
      end

      def ==(other)
        return true if equal?(other)

        other.is_a?(Nested) && @key == other.key && @node == other.node
      end

      def &(other)
        return self if other.is_a?(Empty)

        if other.is_a?(Nested) && @key == other.key
          Nested.new(@key, @node & other.node)
        elsif other.is_a?(And)
          nodes = other.nodes
          index = nodes.find_index { _1.is_a?(Nested) && _1.key == @key }

          if index
            new_nodes = nodes.dup
            new_nodes[index] = self & nodes[index]
          else
            new_nodes = [self] + nodes
          end

          And.new(new_nodes)
        else
          And.new([self, other])
        end
      end

      def |(other)
        return self if other.is_a?(Empty)

        if other.is_a?(Nested) && other.key == @key
          Nested.new(@key, @node | other.node)
        elsif other.is_a?(Or)
          nodes = other.nodes
          index = nodes.find_index { _1.is_a?(Nested) && _1.key == @key }

          if index
            new_nodes = nodes.dup
            new_nodes[index] = self | nodes[index]
          else
            new_nodes = [self] + nodes
          end

          Or.new(new_nodes)
        else
          Or.new([self, other])
        end
      end
    end
  end
end
