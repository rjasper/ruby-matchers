# frozen_string_literal: true

module Matcher
  class ExpressionCache < ExpressionLabeler
    def initialize
      super

      @cache = Hash.new.compare_by_identity
      @index = [Variable.actual]
    end

    def [](expression)
      @index[label(expression)]
    end

    def label(expression, actual_label = ROOT)
      cached_label = @cache[expression]

      return cached_label if cached_label

      count = @label_count
      label = super

      if label > count
        expression = Variable.cache(expression.symbol) if
          expression.is_a?(Variable)

        @cache[expression] = label
        @index[label] = expression
      end

      label
    end
  end
end
