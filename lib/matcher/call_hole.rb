# frozen_string_literal: true

module Matcher
  class CallHole < Hole
    def initialize(key, receiver, method, args, kwargs)
      super(key)

      @receiver = receiver
      @method = method
      @args = args
      @kwargs = kwargs
    end

    def match?(expression, mapping, &)
      return false unless similar?(expression)

      yield expression.receiver, @receiver, mapping.receiver if @receiver

      if @args
        @args.length.times do |i|
          yield expression.args[i], @args[i], mapping.args[i]
        end
      end

      if @kwargs
        expression.kwargs.each_key do |key|
          yield expression.kwargs[key], @kwargs[key], mapping.kwargs[key]
        end
      end

      true
    end

    def similar?(expression)
      expression.is_a?(Call) &&
        !expression.block &&
        (!@args || @args.length == expression.args.length) &&
        (!@method || match_method?(expression.method)) &&
        (!@kwargs || @kwargs.size == expression.kwargs.size &&
          (@kwargs.keys - expression.kwargs.keys).empty?)
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
