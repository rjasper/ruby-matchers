# frozen_string_literal: true

module Matcher
  class ConstantHole < Hole
    def match?(expression)
      expression.is_a?(Constant)
    end

    def to_s
      "const(#{@key.inspect})"
    end
    alias inspect to_s
  end
end
