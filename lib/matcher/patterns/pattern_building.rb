# frozen_string_literal: true

module Matcher
  module PatternBuilding
    include ExpressionBuilding

    def capture(key, pattern)
      pattern = ExpressionRecorder.transform(pattern)
      hole = CaptureHole.new(key, pattern)

      Constant.new(hole).to_recorder
    end

    def hole(key, includes: nil, excludes: nil)
      includes = [includes] if includes.is_a?(Symbol)
      excludes = [excludes] if excludes.is_a?(Symbol)

      hole = Hole.new(key, includes:, excludes:)

      Constant.new(hole).to_recorder
    end

    def actual_hole(key)
      hole(key, includes: :actual)
    end

    def operand_hole(key)
      hole(key, excludes: :actual)
    end

    def var(key)
      hole = VariableHole.new(key)

      Constant.new(hole).to_recorder
    end

    def const(key)
      hole = ConstantHole.new(key)

      Constant.new(hole).to_recorder
    end

    def call_hole(key, receiver: nil, method: nil, args: [], kwargs: {})
      receiver = ExpressionRecorder.transform(receiver)
      args = args&.map { ExpressionRecorder.transform(_1) }
      kwargs = kwargs&.transform_values { ExpressionRecorder.transform(_1) }
      hole = CallHole.new(key, receiver, method, args, kwargs)

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
