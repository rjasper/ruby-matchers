# frozen_string_literal: true

module Matcher
  class Hole
    def initialize(key, includes: nil, excludes: nil)
      @key = key
      @includes = includes
      @excludes = excludes
    end

    attr_reader :key

    def match?(expression, _mapping)
      return false if @includes && !@includes.all? { expression.variables.include?(_1) }
      return false if @excludes && !@excludes.none? { expression.variables.include?(_1) }

      true
    end

    def to_s
      "hole(#{@key.inspect})"
    end
    alias inspect to_s
  end
end
