# frozen_string_literal: true

module Matcher
  class SetExpression < Expression
    def initialize(items)
      super()

      @items = items
    end

    attr_reader :items

    def ==(other)
      return true if equal?(other)

      other.instance_of?(SetExpression) &&
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
      @items.to_set { _1.evaluate(values) }
    end

    def substitute(replacements)
      return self unless replacements.keys.intersect?(variables)

      substituted_items = @items.map { _1.substitute(replacements) }

      SetExpression.new(substituted_items)
    end

    def to_s
      "Set[#{@items.join(', ')}]"
    end
  end
end
