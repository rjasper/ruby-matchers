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

    def match?(expression)
      return false if !expression.is_a?(Call) || !match_method?(expression.method)

      yield Call.new(@receiver, expression.method, @args, @kwargs)

      true
    end

    def to_s
      "method_hole(#{@key.inspect}, #{@receiver}, #{@method.inspect}, #{@args}, #{@kwargs})"
    end
    alias inspect to_s

    private

    def match_method?(method)
      if @method.is_a?(Array)
        @method.include?(method)
      else
        @method === method
      end
    end
  end
end
