# frozen_string_literal: true

module Matcher
  class Expression
    attr_reader :receiver, :method, :args, :kwargs, :block

    def self.build
      recorder = yield ExpressionRecorder.new

      ExpressionRecorder.to_expression(recorder)
    end

    def initialize(receiver = nil, method = nil, *args, **kwargs, &block)
      @receiver = receiver
      @method = method
      @args = args
      @kwargs = kwargs
      @block = block
    end

    def root?
      @receiver.nil?
    end

    def unary?
      @args.empty? && @kwargs.empty? && !@block
    end

    def binary?
      @args.length == 1 && @kwargs.empty? && !@block
    end

    def evaluate(value, chain = nil)
      return value.tap { chain&.push(_1) } unless @receiver

      args = evaluate_args(value)
      kwargs = evaluate_kwargs(value)
      actual_receiver = @receiver.evaluate(value, chain)

      raise NotRespondingError.new(self, actual_receiver, value) unless
        actual_receiver.respond_to?(@method)

      actual_receiver.send(@method, *args, **kwargs, &@block)
        .tap { chain&.push(_1) }
    end

    def rooted
      return self if @receiver&.root?

      Expression.new(Expression.new, @method, *@args, **@kwargs, &@block)
    end

    def eql?(other)
      return true if equal?(other)

      other.is_a?(Expression) &&
        other.receiver.eql?(@receiver) &&
        other.method.eql?(@method) &&
        other.args.eql?(@args) &&
        other.kwargs.eql?(@kwargs) &&
        other.block.eql?(@block)
    end

    def hash
      [@receiver, @args, @method, @kwargs, @block].hash
    end

    def to_s(root: 'value')
      return root if @receiver.nil?

      receiver = @receiver.to_s(root:)

      case @method
      when :!, :~, :+@, :-@
        # !foo
        return "#{@method[0]}#{receiver}" if unary?
      when :+, :-, :*, :/, :%, :<, :>, :<=, :>=, :<=>, :==, :===, :!=, :=~, :!~, :&, :|, :^, :<<, :>>
        # foo + bar
        return "(#{receiver} #{@method} #{@args[0].inspect})" if binary?
      when :**
        # foo**2
        return "(#{receiver}**#{@args[0].inspect})" if binary?
      when :[]
        # foo[a, b, ...]
        return "#{receiver}[#{args_and_kwargs_string}]#{' { ... }' if @block}"
      when :[]=
        # (foo[a, b, ...] = 1)
        if @args.length >= 2 && @kwargs.empty? && !@block
          return "(#{receiver}[#{@args[0..-2].map(&:inspect).join(', ')}] = #{@args[-1].inspect})"
        end
      end

      if @method.end_with?('=') && @method != :[]= && binary?
        # foo.bar = 42

        "(#{receiver}.#{@method[0..-2]} = #{@args[0].inspect})"
      else
        # foo.bar OR foo.bar(arg1, arg2, ...)

        args_and_kwargs = args_and_kwargs_string
        string = "#{receiver}.#{@method}"
        string += "(#{args_and_kwargs})" unless args_and_kwargs.empty?
        string += ' { ... }' if @block

        string
      end
    end
    alias inspect to_s

    class NotRespondingError < StandardError
      attr_reader :expression, :receiver, :value

      def initialize(expression, receiver, value)
        @expression = expression
        @receiver = receiver
        @value = value

        message = "#{@expression.receiver.inspect} does not respond to " \
          "#{@expression.method} where value = #{@value.inspect}"

        super(message)
      end

      def message_for_errors
        expression = @expression.receiver.inspect
        method = @expression.method
        actual = @receiver.inspect
        value = @value.inspect

        string = "expected #{expression} to respond to #{method} but got #{actual}"
        string += " where value = #{value}" if expression != 'value'

        string
      end
    end

    private

    def evaluate_args(value)
      @args.map do |arg|
        arg.is_a?(Expression) ? arg.evaluate(value) : arg
      end
    end

    def evaluate_kwargs(value)
      @kwargs.transform_values do |kwarg|
        kwarg.is_a?(Expression) ? kwarg.evaluate(value) : kwarg
      end
    end

    def args_and_kwargs_string
      args = @args.map(&:inspect)
      kwargs = @kwargs.map do |k, v|
        if k.is_a?(Symbol)
          "#{k}: #{v.inspect}"
        else
          "#{k.inspect} => #{v.inspect}"
        end
      end

      (args + kwargs).join(', ')
    end
  end
end
