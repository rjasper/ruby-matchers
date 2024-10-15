# frozen_string_literal: true

module Matcher
  class ExpressionRecorder
    def self.recorder?(object)
      object.__class__ == ExpressionRecorder
    rescue NoMethodError
      false
    end

    def self.to_expression(recorder)
      raise "no recorder given, got #{recorder.inspect}" unless recorder?(recorder)

      recorder.__expression__
    end

    def self.transform(object)
      return object unless recorder?(object)

      ExpressionRecorder.to_expression(object)
    end

    def self.record(recorder, method, *args, **kwargs, &block)
      receiver = ExpressionRecorder.to_expression(recorder)
      args = args.map { transform(_1) }
      kwargs = kwargs.transform_values { transform(_1) }
      expression = Call.new(receiver, method, args, kwargs, block)

      ExpressionRecorder.new(expression)
    end

    def initialize(expression)
      @expression = expression
    end

    alias __class__ class

    (instance_methods - %i[__id__ __send__ __class__ object_id])
      .each { undef_method _1 }

    def __expression__
      @expression
    end

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
