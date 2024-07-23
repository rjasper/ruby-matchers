# frozen_string_literal: true

module Matcher
  class ExpressionRecorder
    def self.to_expression(recorder)
      raise "no recorder given, got #{recorder.inspect}" if recorder.class != ExpressionRecorder

      recorder.instance_exec { @expression }
    end

    def self.transform(object)
      return object if object.class != ExpressionRecorder

      ExpressionRecorder.to_expression(object)
    end

    def self.record(recorder, method, *args, **kwargs, &)
      receiver = ExpressionRecorder.to_expression(recorder)
      args = args.map { transform(_1) }
      kwargs = kwargs.transform_values { transform(_1) }
      expression = Expression.new(receiver, method, *args, **kwargs, &)

      ExpressionRecorder.new(expression)
    end

    def initialize(expression = Expression.new)
      @expression = expression
    end

    (instance_methods - %i[__id__ __send__ object_id class instance_exec])
      .each { undef_method _1 }

    %w[! == != <=> === =~ !~].each do |operator|
      class_eval <<~CODE, __FILE__, __LINE__ + 1
        def #{operator}(...)                                                    # def ==(...)
          ExpressionRecorder.record(self, :#{operator}, ...)                    #   ExpressionRecorder.record(self, :==, ...)
        end                                                                     # end
      CODE
    end

    def method_missing(...)
      ExpressionRecorder.record(self, ...)
    end

    def respond_to_missing?(...)
      true
    end
  end
end
