# frozen_string_literal: true

module Matcher
  class TransformBuilder
    include Singleton

    def call(match, receiver, method, *args, **kwargs)
      expression = Call.new(
        receiver.expression,
        method,
        args.map(&:expression),
        kwargs.transform_values(&:expression),
      )

      mapping = TransformMapping.new
      mapping.path = match.mapping.path
      mapping.receiver = receiver.mapping
      mapping.args = args.map(&:mapping)
      mapping.kwargs = kwargs.transform_values(&:mapping)

      PatternCapture.new(expression, mapping)
    end
  end
end
