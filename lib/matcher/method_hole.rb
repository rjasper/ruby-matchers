# frozen_string_literal: true

module Matcher
  class MethodHole < Hole
    def initialize(key, receiver, method, args, kwargs)
      super(key)

      @receiver = receiver
      @method = method
      @args = args
      @kwargs = kwargs
    end

    def match?(expression, mapping)
      return false unless similar?(expression)

      yield expression.receiver, @receiver, mapping.receiver

      @args.each_index do |i|
        yield expression.args[i], @args[i], mapping.args[i]
      end

      expression.kwargs.each_key do |key|
        yield expression.kwargs[key], @kwargs[key], mapping.kwargs[key]
      end

      true
    end

    def to_s
      "method_hole(#{@key.inspect}, #{@receiver}, #{@method.inspect}, #{@args}, #{@kwargs})"
    end
    alias inspect to_s

    private

    def similar?(expression)
      expression.is_a?(Call) &&
        !expression.block &&
        @args.length == expression.args.length &&
        match_method?(expression.method) &&
        @kwargs.size == expression.kwargs.size &&
        @kwargs.keys.sort == expression.kwargs.keys.sort
    end

    def match_method?(method)
      if @method.is_a?(Array)
        @method.include?(method)
      else
        @method === method
      end
    end
  end
end
