# frozen_string_literal: true

module Matcher
  class Recorder
    def self.recorder?(object)
      Object.instance_method(:kind_of?)
        .bind_call(object, Recorder)
    end

    def self.to_expression(recorder)
      Object.instance_method(:instance_variable_get)
        .bind_call(recorder, :@expression)
    end

    (instance_methods - %i[__id__ __send__ object_id])
      .each { undef_method _1 }

    def initialize(expression)
      @expression = expression
    end

    def method_missing(method, *args, **kwargs, &block)
      # *.hash.to_int indicates that "*" is used in a Hash as key
      return @expression.receiver.hash if method == :to_int &&
        @expression.is_a?(Call) &&
        @expression.method == :hash &&
        args.empty? && kwargs.empty? && !block &&
        @expression.unary?

      expression_cache = Expression.current_cache
      args = args.map { Expression.of(_1, expression_cache:) }
      kwargs = kwargs.transform_values { Expression.of(_1, expression_cache:) }
      block = Matcher::Block.build(expression_cache:, &block) if
        block && !Matcher.settings[:pass_through_blocks]

      expression = Call.new(@expression, method, args, kwargs, block)
      expression = expression_cache[expression] if expression_cache
      expression.to_recorder
    end

    def respond_to_missing?(_method, _include_private = false)
      true
    end
  end
end
