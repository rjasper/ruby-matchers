# frozen_string_literal: true

module Matcher
  class NestedError < Error
    def self.from(key, node)
      return node if node.is_a?(EmptyError) || key == Variable.actual

      key = Call.new(Variable.actual, :[], [Constant.new(key)]) unless key.is_a?(Expression)

      NestedError.new(key, node)
    end

    def self.key_to_s(key, path)
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
    end

    attr_reader :key, :node

    def initialize(key, node)
      super()

      @key = key
      @node = node
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(NestedError) &&
        @key.eql?(other.key) &&
        @node == other.node
    end

    def &(other)
      return self if other.is_a?(EmptyError)

      if other.is_a?(NestedError) && @key == other.key
        NestedError.new(@key, @node & other.node)
      elsif other.is_a?(AndError)
        nodes = other.nodes
        index = nodes.find_index { _1.is_a?(NestedError) && _1.key == @key }

        if index
          new_nodes = nodes.dup
          new_nodes[index] = self & nodes[index]
        else
          new_nodes = [self] + nodes
        end

        AndError.new(new_nodes)
      else
        AndError.new([self, other])
      end
    end

    def |(other)
      return self if other.is_a?(EmptyError)

      if other.is_a?(NestedError) && other.key == @key
        NestedError.new(@key, @node | other.node)
      elsif other.is_a?(OrError)
        nodes = other.nodes
        index = nodes.find_index { _1.is_a?(NestedError) && _1.key == @key }

        if index
          new_nodes = nodes.dup
          new_nodes[index] = self | nodes[index]
        else
          new_nodes = [self] + nodes
        end

        OrError.new(new_nodes)
      else
        OrError.new([self, other])
      end
    end

    def to_s
      "#{@key} -> #{@node}"
    end
  end
end
