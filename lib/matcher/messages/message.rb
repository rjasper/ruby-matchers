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

    def namespace
      @key.is_a?(Array) ? @key[0] : nil
    end

    def to_standard
      return self if namespace != :expression

      key = @key[1]

      case key
      when :truthy
        _expr, value = @args
        Message.new(key, @negated, value)
      when :same
        _l_expr, _r_expr, left, right = @args
        Message.new(:same, @negated, left, right)
      when :comparable_to, :having_key, :in, :including, :matching, :instance_of, :kind_of, :responding_to, :predicate
        _expr, value, operand = @args
        Message.new(key, @negated, value, operand)
      when :between, :length_of
        _expr, value, operand1, operand2 = @args
        Message.new(key, @negated, value, operand1, operand2)
      when :comparison
        expr, left, right = @args

        case expr.method
        when :==
          Message.new(:equal, @negated, left, right)
        when :!=
          Message.new(:equal, !@negated, left, right)
        when :<
          Message.new(:less_than, @negated, left, right)
        when :>
          Message.new(:greater_than, @negated, left, right)
        when :<=
          Message.new(:less_than_or_equal, @negated, left, right)
        when :>=
          Message.new(:greater_than_or_equal, @negated, left, right)
        else
          raise "unexpected method: #{expr.method.inspect}"
        end
      else
        self
      end
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
