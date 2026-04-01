# frozen_string_literal: true

module Matcher
  class ExpressionCache < ExpressionLabeler
    def self.current(build_session = Matcher.build_session)
      build_session[:_expression_cache] ||= new if build_session
    end

    def initialize
      super

      @cache = {}.compare_by_identity
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
        if expression.is_a?(Variable)
          symbol = expression.symbol
          expression = Variable.send(symbol) if Variable.well_known?(symbol)
        end

        @cache[expression] = label
        @index[label] = expression
      end

      label
    end

    def constant_for(value)
      label = label_for(@constant_labels, value)
      @index[label] ||= Constant.new(value)
    end

    def variable_for(symbol)
      return Variable.send(symbol) if Variable.well_known?(symbol)

      less_known_variable_for(symbol)
    end

    def less_known_variable_for(symbol)
      label = label_for(@variable_labels, symbol)
      @index[label] ||= Variable.new(symbol)
    end
  end
end
