# frozen_string_literal: true

module Matcher
  class Call < Expression
    attr_reader :receiver, :method, :args, :kwargs, :block

    def self.build(*symbols)
      symbols.unshift(:actual) if symbols.empty?

      recorders = symbols.map do |symbol|
        variable = Variable.new(symbol)
        ExpressionRecorder.new(variable)
      end

      recorder = yield *recorders

      ExpressionRecorder.to_expression(recorder)
    end

    UNARY_OPERATORS = %i[! ~ +@ -@].freeze
    BINARY_OPERATORS = %i[+ - * ** / % < > <= >= <=> == === != =~ !~ & | ^ << >> && ||].freeze

    OPERATOR_PRECEDENCE = begin
      precedence = {}

      # see https://ruby-doc.org/3.2.2/syntax/precedence_rdoc.html
      [
        %i[! ~ +@],
        %i[**],
        %i[-@],
        %i[* / %],
        %i[+ -],
        %i[<< >>],
        %i[&],
        %i[| ^],
        %i[> >= < <=],
        %i[<=> == === != =~ !~],
        %i[&&],
        %i[||],
      ].each_with_index do |operators, index|
        operators.each { precedence[_1] = index }
      end

      precedence.freeze
    end

    def self.last_assign
      Matcher.build_session&.dig(Call, :last_assign)
    end

    def self.reset_last_assign
      Matcher.build_session&.[](Call)&.delete(:last_assign)
    end

    def initialize(receiver, method, *args, **kwargs, &block)
      @receiver = receiver
      @method = method
      @args = args
      @kwargs = kwargs
      @block = block

      if binary? && Matcher.settings[:logical_operators]
        case method
        when :&
          @method = :'&&'
        when :|
          @method = :'||'
        end
      end

      set_last_assign if method.end_with?('=')
    end

    def unary?
      @args.empty? && @kwargs.empty? && !@block
    end

    def binary?
      @args.length == 1 && @kwargs.empty? && !@block
    end

    def negated
      @negated ||= begin
        if unary? && @method == :!
          @receiver
        elsif binary? && %i[< > <= >= == != =~ !~ && ||].include?(@method)
          case @method
          when :<
            Call.new(@receiver, :>=, *@args)
          when :>
            Call.new(@receiver, :<=, *@args)
          when :<=
            Call.new(@receiver, :>, *@args)
          when :>=
            Call.new(@receiver, :<, *@args)
          when :==
            Call.new(@receiver, :!=, *@args)
          when :!=
            Call.new(@receiver, :==, *@args)
          when :=~
            Call.new(@receiver, :!~, *@args)
          when :!~
            Call.new(@receiver, :=~, *@args)
          when :'&&'
            Call.new(@receiver.negated, :'||', Expression.negate(@args[0]))
          when :'||'
            Call.new(@receiver.negated, :'&&', Expression.negate(@args[0]))
          else
            raise "Unexpected method: #{method.inspect}"
          end
        else
          super
        end
      end
    end

    def precedence
      has_precedence = (unary? && UNARY_OPERATORS.include?(@method)) ||
        (binary? && BINARY_OPERATORS.include?(@method))

      # if method is not an operator then precedence is highest (-1)
      has_precedence ? OPERATOR_PRECEDENCE[@method] : -1
    end

    def evaluate(values, chain = nil)
      actual_receiver = @receiver.evaluate(values, chain)

      return actual_receiver if @method == :'&&' && !actual_receiver
      return actual_receiver if @method == :'||' && actual_receiver

      args = evaluate_args(values)
      kwargs = evaluate_kwargs(values)

      return args[0] if %i[&& ||].include?(@method)

      raise NotRespondingError.new(self, actual_receiver, values) unless
        actual_receiver.respond_to?(@method)

      actual_receiver.send(@method, *args, **kwargs, &@block)
        .tap { chain&.push(_1) }
    end

    def variables
      @variables ||= begin
        variables_from_arg = lambda do |arg|
          arg.is_a?(Expression) ? arg.variables : []
        end

        variables = @receiver.variables +
          @args.flat_map(&variables_from_arg) +
          @kwargs.each_value.flat_map(&variables_from_arg)

        variables.uniq
      end
    end

    def new_root(receiver)
      Call.new(receiver, @method, *@args, **@kwargs, &@block)
    end

    def ==(other)
      return true if equal?(other)

      other.is_a?(Call) &&
        other.receiver == @receiver &&
        other.method == @method &&
        other.args == @args &&
        other.kwargs == @kwargs &&
        other.block == @block
    end

    def eql?(other)
      return true if equal?(other)

      other.is_a?(Call) &&
        other.receiver.eql?(@receiver) &&
        other.method.eql?(@method) &&
        other.args.eql?(@args) &&
        other.kwargs.eql?(@kwargs) &&
        other.block.eql?(@block)
    end

    def hash
      @hash ||= [@receiver, @args, @method, @kwargs, @block].hash
    end

    def to_s(substitutions: Expression.default_substitutions)
      receiver = parenthesize(@receiver, substitutions)

      case @method
      when :!, :~, :+@, :-@
        # !foo
        return "#{@method[0]}#{receiver}" if unary?
      when :+, :-, :*, :/, :%, :<, :>, :<=, :>=, :<=>, :==, :===, :!=, :=~, :!~, :&, :|, :^, :<<, :>>, :'&&', :'||'
        # foo + bar
        return "#{receiver} #{@method} #{parenthesize(@args[0], substitutions)}" if binary?
      when :**
        # foo**2
        return "#{receiver}**#{parenthesize(@args[0], substitutions)}" if binary?
      when :[]
        # foo[a, b, ...]
        return "#{receiver}[#{args_and_kwargs_string}]#{' { ... }' if @block}"
      when :[]=
        # foo[a, b, ...] = 1
        if @args.length >= 2 && @kwargs.empty? && !@block
          return "#{receiver}[#{@args[0..-2].map(&:inspect).join(', ')}] = #{@args[-1].inspect}"
        end
      end

      if @method.end_with?('=') && @method != :[]= && binary?
        # foo.bar = 42

        "#{receiver}.#{@method[0..-2]} = #{@args[0].inspect}"
      else
        # foo.bar OR foo.bar(arg1, arg2, ...)

        args_and_kwargs = args_and_kwargs_string
        string = "#{receiver}.#{@method}"
        string += "(#{args_and_kwargs})" unless args_and_kwargs.empty?
        string += ' { ... }' if @block

        string
      end
    end

    class NotRespondingError < StandardError
      attr_reader :call, :receiver, :values

      def initialize(call, receiver, values)
        @call = call
        @receiver = receiver
        @values = values

        message = "#{@call.receiver.inspect} does not respond to " \
          "#{@call.method} where #{@call.given_values(values)}"

        super(message)
      end

      def message_for_errors
        expression = @call.receiver.inspect
        method = @call.method
        actual = @receiver.inspect

        string = "expected #{expression} to respond to #{method} but got #{actual}"
        string += " where #{@call.given_values(@values)}" if @call.receiver.instance_of?(Call)

        string
      end
    end

    def given_values(values, substitutions: Expression.default_substitutions)
      parts = variables.filter_map do |symbol|
        value = values[symbol]
        next if value.nil? && !values.key?(symbol)

        substitution = substitutions&.[](symbol)

        "#{substitution || symbol} = #{value.inspect}"
      end

      parts.join(', ')
    end

    private

    def set_last_assign
      build_session = Matcher.build_session

      return unless build_session

      call_session = (build_session[Call] ||= {})
      call_session[:last_assign] = self
    end

    def evaluate_args(values)
      @args.map do |arg|
        arg.is_a?(Expression) ? arg.evaluate(values) : arg
      end
    end

    def evaluate_kwargs(values)
      @kwargs.transform_values do |kwarg|
        kwarg.is_a?(Expression) ? kwarg.evaluate(values) : kwarg
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

    def parenthesize(operand, substitutions)
      return operand.inspect unless operand.is_a?(Expression)

      operand_string = operand.to_s(substitutions:)

      return operand_string unless operand.instance_of?(Call)

      # if operand's precedence is lower (higher index) than ours
      operand.precedence > precedence ? "(#{operand_string})" : operand_string
    end
  end
end
