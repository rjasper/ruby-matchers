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
      args = @args.map(&:inspect)
      kwargs = @kwargs.map { "#{_1}: #{_2.inspect}" }
      list = [@key.inspect, @receiver, @method.inspect].concat(args, kwargs)

      "method_hole(#{list.join(', ')})"
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
