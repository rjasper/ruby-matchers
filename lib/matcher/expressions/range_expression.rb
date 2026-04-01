# frozen_string_literal: true

module Matcher
  class RangeExpression < Expression
    def initialize(from, to, exclude_end = false)
      super()

      @begin = from
      @end = to
      @exclude_end = exclude_end
    end

    attr_reader :begin, :end

    def exclude_end?
      @exclude_end
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(RangeExpression) &&
        other.begin.eql?(@begin) &&
        other.end.eql?(@end) &&
        other.exclude_end?.eql?(@exclude_end)
    end
    alias eql? ==

    def hash
      [self.class, @begin, @end, @exclude_end].hash
    end

    def variables
      @variables ||= (@begin.variables + @end.variables).uniq
    end

    def evaluate(values)
      from = @begin.evaluate(values)
      to = @end.evaluate(values)

      Range.new(from, to, @exclude_end)
    end

    def substitute(replacements)
      return self unless replacements.keys.intersect?(variables)

      from = @begin.substitute(replacements)
      to = @end.substitute(replacements)

      RangeExpression.new(from, to, @exclude_end)
    end

    def to_s
      dots = @exclude_end ? '...' : '..'

      "#{@begin}#{dots}#{@end}"
    end
  end
end
