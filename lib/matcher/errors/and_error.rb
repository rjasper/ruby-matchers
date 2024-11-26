# frozen_string_literal: true

module Matcher
  class AndError < Error
    attr_reader :nodes

    def self.from(nodes)
      length = nodes.length

      return EmptyError.instance if length == 0

      nodes.reduce do |left, right|
        if left.is_a?(AndError)
          left << right
        else
          left & right
        end
      end
    end

    def initialize(nodes)
      raise 'nodes fewer than 2' if nodes.length < 2

      super()

      @nodes = nodes
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(AndError) &&
        @nodes == other.nodes
    end

    def &(other)
      return self if other.is_a?(EmptyError)

      clone << other
    end

    def add(other)
      case other
      when AndError
        right = other.nodes.dup

        @nodes.each_with_index do |l, i|
          next unless l.is_a?(NestedError)

          index = right.find_index { _1.is_a?(NestedError) && _1.key == l.key }

          @nodes[i] = l & right.delete_at(index) if index
        end

        @nodes.concat(right)
      when NestedError
        index = @nodes.find_index { _1.is_a?(NestedError) && _1.key == other.key }

        if index
          @nodes[index] &= other
        else
          @nodes << other
        end
      else
        @nodes << other
      end

      self
    end
    alias << add

    def clone
      klone = super
      klone.instance_exec do
        @nodes = @nodes.dup
      end

      klone
    end
    alias dup clone

    def to_s
      @nodes.map(&:to_s).join(' & ')
    end
  end
end
