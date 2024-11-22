# frozen_string_literal: true

module Matcher
  class VariableHole < Hole
    def match?(expression)
      expression.is_a?(Variable)
    end

    def to_s
      "var(#{@key.inspect})"
    end
    alias inspect to_s
  end
end
