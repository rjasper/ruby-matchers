# frozen_string_literal: true

module Matcher
  module PatternBuilding
    include ExpressionBuilding

    def capture(key, pattern)
      pattern = ExpressionRecorder.transform(pattern)
      hole = CaptureHole.new(key, pattern)

      Constant.new(hole).to_recorder
    end

    def hole(key)
      hole = Hole.new(key)

      Constant.new(hole).to_recorder
    end

    def var(key)
      hole = VariableHole.new(key)

      Constant.new(hole).to_recorder
    end

    def const(key)
      hole = ConstantHole.new(key)

      Constant.new(hole).to_recorder
    end

    def method_hole(key, receiver, method, *args, **kwargs)
      receiver = ExpressionRecorder.transform(receiver)
      args = args&.map { ExpressionRecorder.transform(_1) }
      kwargs = kwargs&.transform_values { ExpressionRecorder.transform(_1) }
      hole = MethodHole.new(key, receiver, method, args, kwargs)

      Constant.new(hole).to_recorder
    end
  end
end
