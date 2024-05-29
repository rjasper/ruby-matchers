# frozen_string_literal: true

module Matcher
  class Expression
    attr_reader :receiver, :method, :args, :kwargs

    def initialize(receiver = nil, method = nil, *args, **kwargs, &block)
      @receiver = receiver
      @method = method
      @args = args
      @kwargs = kwargs
      @block = block
    end

    COMPARISONS = %i[== < > <= >= != =~ !~].freeze

    def comparison?
      @method.in?(COMPARISONS) && @args.length == 1 && @kwargs.empty? && !@block
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

    def to_s
      return 'value' if @receiver.nil?

      case @method
      when :!, :~, :+@, :-@
        # !foo
        return "#{@method[0]}#{@receiver}" if @args.length == 0
      when :+, :-, :*, :/, :%, :**, :<, :>, :<=, :>=, :<=>, :==, :===, :!=, :=~, :!~, :&, :|, :^, :<<, :>>
        # foo + bar
        return "(#{@receiver} #{@method} #{@args[0].inspect})" if @args.length == 1
      when :[]
        # foo[a, b, ...]
        return "#{@receiver}[#{args_and_kwargs_string}]"
      when :[]=
        # (foo[a, b, ...] = 1)
        return "(#{@receiver}[#{@args[0..-2].map(&:inspect).join(', ')}] = #{@args[-1].inspect})"
      end

      if @method.end_with?('=') && @args.length == 1
        # foo.bar = 42

        "(#{@receiver}.#{@method[0..-2]} = #{@args[0]})"
      else
        # foo.bar OR foo.bar(arg1, arg2, ...)

        args_and_kwargs = args_and_kwargs_string
        string = "#{@receiver}.#{@method}"
        string += "(#{args_and_kwargs})" unless args_and_kwargs.empty?

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
