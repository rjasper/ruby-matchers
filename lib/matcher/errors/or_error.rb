# frozen_string_literal: true

module Matcher
  class OrError < Error
    attr_reader :children

    def self.from(children)
      length = children.length

      return EmptyError.instance if length == 0

      children.reduce do |left, right|
        if left.is_a?(OrError)
          left << right
        else
          left | right
        end
      end
    end

    def initialize(children)
      raise 'children fewer than 2' if children.length < 2

      super()

      @children = children
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(OrError) &&
        @children == other.children
    end

    def |(other)
      return self if other.is_a?(EmptyError)

      clone << other
    end

    def add(other)
      case other
      when OrError
        right = other.children.dup

        @children.each_with_index do |l, i|
          next unless l.is_a?(NestedError)

          index = right.find_index { _1.is_a?(NestedError) && _1.key == l.key }

          @children[i] = l | right.delete_at(index) if index
        end

        @children.concat(right)
      when NestedError
        index = @children.find_index { _1.is_a?(NestedError) && _1.key == other.key }

        if index
          @children[index] |= other
        else
          @children << other
        end
      else
        @children << other
      end

      self
    end
    alias << add

    def clone
      klone = super
      klone.instance_exec do
        @children = @children.dup
      end

      klone
    end
    alias dup clone

    def to_s
      "(#{@children.map(&:to_s).join(' | ')})"
    end
  end
end
