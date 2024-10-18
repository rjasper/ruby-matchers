# frozen_string_literal: true

module Matcher
  module Errors
    class Nested < Node
      def self.from(key, node)
        return node if node.is_a?(Empty)

        keys = if key.is_a?(Array)
          key
        elsif key.is_a?(Expression)
          NestedExpressionNormalizer.normalize(key)
        else
          return Nested.new(key, node)
        end

        keys.reverse_each.reduce(node) { Nested.new(_2, _1) }
      end

      def self.key_to_s(key, path)
        case key
        when Expression
          remaining = 20 + path.length
          key.visit do |expr|
            next if !expr.is_a?(Variable) || expr.symbol != :actual

            remaining -= path.length
            break if remaining < 0
          end

          if remaining >= 0
            key.to_s(substitutions: { actual: path })
          else
            "#{path} -> #{key}"
          end
        when Errors::Nested::Key
          path + key.to_s
        else
          "#{path}[#{key.inspect}]"
        end
      end

      class Key
        def initialize(str)
          @str = str
        end

        def hash
          @str.hash
        end

        def eql?(other)
          other.is_a?(Key) && other.str.eql?(@str)
        end

        protected attr_reader :str

        def to_s
          @str
        end
        alias inspect to_s
      end

      attr_reader :key, :node

      def initialize(key, node)
        @key = key
        @node = node
      end

      def ==(other)
        return true if equal?(other)

        other.instance_of?(Nested) &&
          @key.eql?(other.key) &&
          @node == other.node
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

      def to_s
        "#{@key} -> #{@node}"
      end
    end
  end
end
