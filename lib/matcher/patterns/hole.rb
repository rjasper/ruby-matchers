# frozen_string_literal: true

module Matcher
  class Hole
    def initialize(key)
      @key = key
    end

    attr_reader :key

    def match?(expression, _mapping)
      true
    end

    def to_s
      "hole(#{@key.inspect})"
    end
    alias inspect to_s
  end
end
