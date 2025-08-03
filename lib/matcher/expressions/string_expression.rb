# frozen_string_literal: true

module Matcher
  class StringExpression < Expression
    def initialize(parts)
      super()

      @parts = parts
    end

    attr_reader :parts

    def ==(other)
      return true if equal?(other)

      other.instance_of?(StringExpression) &&
        @parts.eql?(other.parts)
    end
    alias eql? ==

    def hash
      @hash ||= [self.class, @parts].hash
    end

    def variables
      @variables ||= @parts.flat_map(&:variables).uniq
    end

    def evaluate(values)
      @parts.map { _1.evaluate(values) }.join
    end

    def substitute(replacements)
      return self unless replacements.keys.intersect?(variables)

      substituted_parts = @parts.map { _1.substitute(replacements) }

      StringExpression.new(substituted_parts)
    end

    def to_s(substitutions: Expression.default_substitutions)
      parts = @parts.map do |part|
        if part.is_a?(Constant) && part.value.is_a?(String)
          part.value
        else
          "\#{#{part.to_s(substitutions:)}}"
        end
      end

      "\"#{parts.join}\""
    end
  end
end
