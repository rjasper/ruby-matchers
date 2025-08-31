# frozen_string_literal: true

module Matcher
  module PatternBuilding
    include ExpressionBuilding

    def pattern_of(value)
      Pattern.new(expression_of(value))
    end

    def capture(key, pattern)
      pattern = expression_of(pattern)
      hole = CaptureHole.new(key, pattern)

      expr(hole)
    end

    def hole(key)
      expr(Hole.new(key))
    end

    def var(key)
      expr(VariableHole.new(key))
    end

    def const(key)
      expr(ConstantHole.new(key))
    end

    def method_hole(key, receiver, method, *args, **kwargs)
      receiver = expression_of(receiver)
      args = args.map { expression_of(_1) }
      kwargs = kwargs.transform_values { expression_of(_1) }
      hole = MethodHole.new(key, receiver, method, args, kwargs)

      expr(hole)
    end
  end
end
