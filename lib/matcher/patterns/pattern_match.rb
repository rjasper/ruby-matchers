# frozen_string_literal: true

module Matcher
  class PatternMatch
    def initialize
      @captures = {}
    end

    def [](key)
      @captures[key]
    end

    def include?(key)
      @captures.include?(key)
    end

    def capture(key, expression, mapping)
      @captures[key] = PatternCapture.new(expression, mapping)
    end

    def value_paths
      @captures.transform_values(&:value_path)
    end

    def expressions
      @captures.transform_values(&:expression)
    end
  end
end
