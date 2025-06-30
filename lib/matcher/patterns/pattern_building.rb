# frozen_string_literal: true

module Matcher
  module PatternBuilding
    include ExpressionBuilding

    def capture(key, pattern)
      pattern = Expression.of(pattern)

      CaptureHole.new(key, pattern).to_recorder
    end

    def hole(key)
      Hole.new(key).to_recorder
    end

    def var(key)
      VariableHole.new(key).to_recorder
    end

    def const(key)
      ConstantHole.new(key).to_recorder
    end

    def method_hole(key, receiver, method, *args, **kwargs)
      of = Expression.method(:of)
      receiver = Expression.of(receiver)
      args = args&.map(&of)
      kwargs = kwargs&.transform_values(&of)

      MethodHole.new(key, receiver, method, args, kwargs).to_recorder
    end
  end
end
