# frozen_string_literal: true

module Matcher
  class Call < Expression
    attr_reader :receiver, :method, :args, :kwargs, :block

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

    def initialize(receiver, method, args = [], kwargs = {}, block = nil)
      super()

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
      knary?(0)
    end

    def binary?
      knary?(1)
    end

    def ternary?
      knary?(2)
    end

    def knary?(arity)
      @args.length == arity && @kwargs.empty? && !@block
    end

    def assignment?
      @method.end_with?('=') && !%i[<= >= == === !=].include?(@method)
    end

    def negated
      @negated ||= begin
        if unary? && @method == :!
          @receiver
        elsif binary? && %i[< > <= >= == != =~ !~ && ||].include?(@method)
          case @method
          when :<
            Call.new(@receiver, :>=, @args)
          when :>
            Call.new(@receiver, :<=, @args)
          when :<=
            Call.new(@receiver, :>, @args)
          when :>=
            Call.new(@receiver, :<, @args)
          when :==
            Call.new(@receiver, :!=, @args)
          when :!=
            Call.new(@receiver, :==, @args)
          when :=~
            Call.new(@receiver, :!~, @args)
          when :!~
            Call.new(@receiver, :=~, @args)
          when :'&&'
            Call.new(@receiver.negated, :'||', [Expression.negate(@args[0])])
          when :'||'
            Call.new(@receiver.negated, :'&&', [Expression.negate(@args[0])])
          else
            raise "Unexpected method: #{method.inspect}"
          end
        else
          super
        end
      end
    end

    def precedence
      @precedence ||= begin
        has_precedence = (unary? && UNARY_OPERATORS.include?(@method)) ||
          (binary? && BINARY_OPERATORS.include?(@method))

        # if method is not an operator then precedence is highest (-1)
        has_precedence ? OPERATOR_PRECEDENCE[@method] : -1
      end
    end

    def evaluate(values)
      receiver = @receiver.evaluate(values)

      return receiver if lazy?(receiver)

      args = @args.map { _1.evaluate(values) }
      kwargs = @kwargs.transform_values { _1.evaluate(values) }

      return args[0] if logical_operator?

      invoke(values, receiver, args, kwargs)
    end

    def evaluate_tree(values)
      receiver_t = @receiver.evaluate_tree(values)
      receiver = receiver_t.last

      return [receiver_t, nil, nil, receiver] if lazy?(receiver)

      args, args_t = evaluate_args_tree(values)
      kwargs, kwargs_t = evaluate_kwargs_tree(values)

      return [receiver_t, args_t, kwargs_t, args[0]] if logical_operator?

      value = invoke(values, receiver, args, kwargs)

      [receiver_t, args_t, kwargs_t, value]
    end

    def variables
      @variables ||= begin
        variables_from_arg = lambda do |arg|
          arg.is_a?(Expression) ? arg.variables : []
        end

        variables = @receiver.variables +
          @args.flat_map(&variables_from_arg) +
          @kwargs.each_value.flat_map(&variables_from_arg)

        variables.concat(@block.variables) if @block

        variables.uniq
      end
    end

    def new_root(receiver)
      Call.new(receiver, @method, @args, @kwargs, @block)
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(Call) &&
        other.receiver == @receiver &&
        other.method == @method &&
        other.args.eql?(@args) &&
        other.kwargs.eql?(@kwargs) &&
        other.block == @block
    end
    alias eql? ==

    def hash
      @hash ||= [@receiver, @args, @method, @kwargs, @block].hash
    end

    def visit(&)
      return to_enum(:visit) unless block_given?

      @receiver.visit(&)
      @args.each { _1.visit(&) if _1.is_a?(Expression) }
      @kwargs.each_value { _1.visit(&) if _1.is_a?(Expression) }

      yield self
    end

    def substitute(replacements)
      replacement_names = replacements.keys

      return self unless replacement_names.intersect?(variables)

      receiver = @receiver.substitute(replacements)

      no_change = nil
      substitute = lambda do |expression|
        if expression.is_a?(Expression)
          result = expression.substitute(replacements)
          no_change = false unless result.equal?(expression)

          result
        else
          expression
        end
      end

      no_change = true
      args = @args.map(&substitute)
      args = @args if no_change

      no_change = true
      kwargs = @kwargs.transform_values(&substitute)
      kwargs = @kwargs if no_change

      block = block.is_a?(Matcher::Block) ? @block.substitute(replacements) : @block

      Call.new(receiver, @method, args, kwargs, block)
    end

    def to_s(substitutions: Expression.default_substitutions)
      receiver = parenthesize(@receiver, false, substitutions)

      case @method
      when :!, :~, :+@, :-@
        # !foo
        return "#{@method[0]}#{receiver}" if unary?
      when :+, :-, :*, :/, :%, :**,:<, :>, :<=, :>=, :<=>, :==, :===, :!=, :=~, :!~, :&, :|, :^, :<<, :>>, :'&&', :'||'
        if binary?
          operand = parenthesize(@args[0], true, substitutions)

          # foo**2
          return "#{receiver}**#{operand}" if @method == :**

          # foo + bar
          return "#{receiver} #{@method} #{operand}"
        end
      when :[]
        # foo[a, b, ...]
        return "#{receiver}[#{args_and_kwargs_string(substitutions)}]#{block_string}"
      when :[]=
        # foo[a, b, ...] = 1
        if @args.length >= 2 && @kwargs.empty? && !@block
          first_args = @args[0..-2].map { _1.to_s(substitutions:) }.join(', ')
          last_arg = @args[-1].to_s(substitutions:)

          return "#{receiver}[#{first_args}] = #{last_arg}"
        end
      end

      if @method.end_with?('=') && @method != :[]= && binary?
        # foo.bar = 42

        "#{receiver}.#{@method[0..-2]} = #{@args[0].to_s(substitutions:)}"
      else
        # foo.bar OR foo.bar(arg1, arg2, ...)

        args_and_kwargs = args_and_kwargs_string(substitutions)
        string = "#{receiver}.#{@method}"
        string += "(#{args_and_kwargs})" unless args_and_kwargs.empty?
        string += block_string

        string
      end
    end

    class Error < StandardError
    end

    class NotRespondingError < Error
      attr_reader :call, :receiver, :given

      def initialize(call, receiver, values)
        @call = call
        @receiver = receiver
        @given = values.slice(*call.receiver.variables)

        super("#{call.receiver} does not respond to `#{call.method}'")
      end

      def message_for_errors
        if @call.receiver == Variable.actual
          ErrorMessage.new(:responding_to, true, @receiver, @call.method)
        else
          ErrorMessage.new(
            %i[expression responding_to],
            true,
            nil,
            @call.receiver,
            @receiver,
            @call.method,
            @given,
          )
        end
      end
    end

    class EvaluationError < Error
      attr_reader :error, :call, :given

      def initialize(error, call, values)
        @error = error
        @call = call
        @given = values.slice(*call.variables)

        super("#{call} raised #{error.class}: #{error.message}")
      end

      def message_for_errors
        ErrorMessage.new(%i[expression raising], false, nil, @call, @error, @given)
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

    def lazy?(receiver)
      @method == :'&&' && !receiver || @method == :'||' && receiver
    end

    def logical_operator?
      %i[&& ||].include?(@method)
    end

    def invoke(values, receiver, args, kwargs)
      raise NotRespondingError.new(self, receiver, values) unless
        receiver.respond_to?(@method)

      begin
        block = @block.is_a?(Matcher::Block) ? @block&.to_proc(values:) : @block
        result = receiver.send(@method, *args, **kwargs, &block)

        assignment? ? args.last : result
      rescue StandardError => e
        raise EvaluationError.new(e, self, values)
      end
    end

    def set_last_assign
      build_session = Matcher.build_session

      return unless build_session

      call_session = (build_session[Call] ||= {})
      call_session[:last_assign] = self
    end

    def evaluate_args_tree(values)
      n = @args.length
      args = Array.new(n)
      args_t = Array.new(n)

      @args.each_with_index do |arg, i|
        arg_t = arg.evaluate_tree(values)
        args[i] = arg_t.last
        args_t[i] = arg_t
      end

      [args, args_t]
    end

    def evaluate_kwargs_tree(values)
      kwargs = {}
      kwargs_t = {}

      @kwargs.each do |key, kwarg|
        kwarg_t = kwarg.evaluate_tree(values)
        kwargs[key] = kwarg_t.last
        kwargs_t[key] = kwarg_t
      end

      [kwargs, kwargs_t]
    end

    def args_and_kwargs_string(substitutions)
      args = @args.map { _1.to_s(substitutions:)}
      kwargs = @kwargs.map do |k, v|
        if k.is_a?(Symbol)
          "#{k}: #{v.inspect}"
        else
          "#{k.inspect} => #{v.to_s(substitutions:)}"
        end
      end

      list = args + kwargs
      list << "&#{@block.symbol.inspect}" if @block&.is_a?(SymbolProc)

      list.join(', ')
    end

    def block_string
      if @block.is_a?(Block)
        " #{@block.to_s(as_block: true)}"
      elsif @block && !@block.is_a?(SymbolProc)
        ' { ... }'
      else
        ''
      end
    end

    def parenthesize(operand, is_rhs, substitutions)
      return operand.inspect unless operand.is_a?(Expression)

      operand_string = operand.to_s(substitutions:)

      return operand_string unless operand.instance_of?(Call)

      # parenthesize if operand's precedence is lower (higher index) than ours
      need_parentheses = if is_rhs
        # also parenthesize rhs if precedence is the same
        operand.precedence >= precedence
      else
        # also parenthesize lhs if both operators are any of: <=> == === != =~ !~
        operand.precedence > precedence ||
          operand.precedence == precedence && %i[<=> == === != =~ !~].include?(@method)
      end

      need_parentheses ? "(#{operand_string})" : operand_string
    end
  end
end
