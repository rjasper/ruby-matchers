# frozen_string_literal: true

module Matcher
  class ArrayExpression < Expression
    def initialize(items)
      super()

      @items = items
    end

    attr_reader :items

    def ==(other)
      return true if equal?(other)

      other.instance_of?(ArrayExpression) &&
        other.items.eql?(@items)
    end
    alias eql? ==

    def hash
      @hash ||= [self.class, @items].hash
    end

    def variables
      @variables ||= @items.flat_map(&:variables).uniq
    end

    def evaluate(values)
      @items.map { _1.evaluate(values) }
    end

    def substitute(replacements)
      return self unless replacements.keys.intersect?(variables)

      substituted_items = @items.map { _1.substitute(replacements) }

      ArrayExpression.new(substituted_items)
    end

    def to_s
      "[#{@items.map(&:to_s).join(', ')}]"
    end
  end
end
