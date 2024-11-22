# frozen_string_literal: true

module Matcher
  module PatternBuilding
    include ExpressionBuilding

    def capture(key, pattern)
      pattern = ExpressionRecorder.transform(pattern)

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
      receiver = ExpressionRecorder.transform(receiver)
      args = args&.map { ExpressionRecorder.transform(_1) }
      kwargs = kwargs&.transform_values { ExpressionRecorder.transform(_1) }

      MethodHole.new(key, receiver, method, args, kwargs).to_recorder
    end
  end
end
