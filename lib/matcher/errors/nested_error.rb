# frozen_string_literal: true

module Matcher
  class NestedError < Error
    def self.from(key, child)
      return child if child.is_a?(EmptyError) || key == Variable.actual

      unless key.is_a?(Expression)
        key = Call.new(Variable.actual, :[], [Constant.new(key)])
      end

      NestedError.new(key, child)
    end

    def self.key_to_s(key, path)
      remaining = 20 + path.length
      key.visit do |expr|
        next if !expr.is_a?(Variable) || expr.symbol != :actual

        remaining -= path.length
        break if remaining < 0
      end

      if remaining >= 0 && key.variables.include?(:actual)
        Variable.with_substitutions(actual: path) do
          key.to_s
        end
      else
        "#{path} -> #{key}"
      end
    end

    attr_reader :key, :child

    def initialize(key, child)
      super()

      @key = key
      @child = child
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(NestedError) &&
        @key.eql?(other.key) &&
        @child == other.child
    end

    def &(other)
      return self if other.is_a?(EmptyError)

      if other.is_a?(NestedError) && @key == other.key
        NestedError.new(@key, @child & other.child)
      elsif other.is_a?(AndError)
        errors = other.children
        index = errors.find_index { _1.is_a?(NestedError) && _1.key == @key }

        if index
          new_errors = errors.dup
          new_errors[index] = self & errors[index]
        else
          new_errors = [self] + errors
        end

        AndError.new(new_errors)
      else
        AndError.new([self, other])
      end
    end

    def |(other)
      return self if other.is_a?(EmptyError)

      if other.is_a?(NestedError) && other.key == @key
        NestedError.new(@key, @child | other.child)
      elsif other.is_a?(OrError)
        errors = other.children
        index = errors.find_index { _1.is_a?(NestedError) && _1.key == @key }

        if index
          new_errors = errors.dup
          new_errors[index] = self | errors[index]
        else
          new_errors = [self] + errors
        end

        OrError.new(new_errors)
      else
        OrError.new([self, other])
      end
    end

    def to_s
      "#{@key} -> #{@child}"
    end
  end
end
