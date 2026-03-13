# frozen_string_literal: true

module Matcher
  class HashExpression < Expression
    def initialize(pairs)
      super()

      @pairs = pairs
    end

    attr_reader :pairs

    def ==(other)
      return true if equal?(other)

      other.instance_of?(self.class) &&
        other.pairs.eql?(@pairs)
    end
    alias eql? ==

    def hash
      @hash ||= [self.class, @pairs].hash
    end

    def variables
      @variables ||= @pairs.flat_map { |k, v| k.variables + v.variables }.uniq
    end

    def evaluate(values)
      @pairs.to_h do |k, v|
        [k.evaluate(values), v.evaluate(values)]
      end
    end

    def substitute(replacements)
      return self unless replacements.keys.intersect?(variables)

      substituted_pairs = @pairs.map do |k, v|
        [k.substitute(replacements), v.substitute(replacements)]
      end

      HashExpression.new(substituted_pairs)
    end

    def to_s
      parts = @pairs.map do |k, v|
        key_part = if k.is_a?(Constant) && k.value.is_a?(Symbol)
          "#{k.value}:"
        else
          "#{k} =>"
        end

        "#{key_part} #{v}"
      end

      "{ #{parts.join(', ')} }"
    end
  end
end
