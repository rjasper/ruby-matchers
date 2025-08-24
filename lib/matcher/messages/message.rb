# frozen_string_literal: true

module Matcher
  class Message
    attr_reader :key, :negated, :actual, :args, :kwargs

    def initialize(key, negated, actual, *args, **kwargs)
      @key = key
      @negated = negated
      @actual = actual
      @args = args
      @kwargs = kwargs
    end

    def negate!
      @negated = !@negated
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(Message) &&
        @key.eql?(other.key) &&
        @negated == other.negated &&
        @actual.eql?(other.actual) &&
        @args.eql?(other.args) &&
        @kwargs.eql?(other.kwargs)
    end
    alias eql? ==

    def hash
      @hash ||= [self.class, @key, @negated, @actual, @args, @kwargs].hash
    end

    def to_s
      if @key.is_a?(Array)
        namespace, key = @key
      else
        key = @key
      end

      args_and_kwargs = @args.map(&:inspect) + @kwargs.map do |k, v|
        k.is_a?(Symbol) ? "#{k}: #{v.inspect}" : "#{k.inspect} => #{v.inspect}"
      end

      string = String.new("report(#{@actual.inspect})")
      string += ".namespace(#{namespace.inspect})" if namespace
      string += '.not' if @negated
      string += ".#{key}"
      string += "(#{args_and_kwargs.join(', ')})" unless args_and_kwargs.empty?

      string
    end
    alias inspect to_s
  end
end
