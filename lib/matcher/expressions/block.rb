    # frozen_string_literal: true

module Matcher
  class Block
    class Context
      attr_reader :expression, :values

      def initialize(expression, values)
        @expression = expression
        @values = values
      end

      def evaluate(values)
        values.merge!(@values) { |_k, _l, r| r }

        @expression.evaluate(values)
      end
    end

    def self.build(&block)
      return SymbolProc.new(block) if
        block.parameters == [[:req], [:rest]] &&
          /\(&:(\w+|".*")\)/.match?(block.to_s)

      parameters = block.parameters
      args = []
      kwargs = {}
      parameter_names = Set.new
      variable_object_ids = Set.new

      parameters.each do |type, name|
        parameter_names << name
        variable = Variable.new(name)
        variable_object_ids << variable.object_id

        case type
        when :req, :opt
          args << variable.to_recorder
        when :key, :keyreq
          kwargs[name] = variable.to_recorder
        when :rest
          raise "*#{name unless name == :*} not allowed"
        when :keyrest
          raise "**#{name unless name == :**} not allowed"
        when :block
          raise "&#{name unless name == :&} not allowed"
        end
      end

      result = block.call(*args, **kwargs)

      if ExpressionRecorder.recorder?(result)
        expression = ExpressionRecorder.to_expression(result)

        return SymbolProc.new(expression.method) if
          args.length == 1 &&
            expression.is_a?(Call) &&
            expression.unary? &&
            expression.receiver == ExpressionRecorder.to_expression(args[0])

        ExpressionWalker.each_variable(expression) do |variable|
          raise "parameter `#{variable.symbol}' shadows an outer variable" if
            parameter_names.include?(variable.symbol) &&
              !variable_object_ids.include?(variable.object_id)
        end
      else
        expression = Constant.new(result)
      end

      new(parameters, expression)
    end

    attr_reader :parameters, :expression

    def initialize(parameters, expression)
      @parameters = parameters
      @expression = expression
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(Block) &&
        @parameters.eql?(other.parameters) &&
        @expression == other.expression
    end
    alias eql? ==

    def hash
      [self.class, @parameters, @expression].hash
    end

    def variables
      @variables ||= @expression.variables - @parameters.map { _2 }
    end

    def substitute(replacements)
      replacements = replacements.slice(*variables)

      return self if replacements.empty?

      expression = @expression.substitute(replacements)

      Block.new(@parameters, expression)
    end

    def to_proc(values: nil)
      @proc ||= begin
        kwlist = @parameters.map { |_type, name| "#{name}:" }.join(', ')

        instance_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          ->(#{arg_list}) { evaluate({ #{kwlist} }) }                           # ->(arg, kwarg:) { evaluate({ arg:, kwarg: }) }
        RUBY
      end

      if values && !variables.empty?
        values = values.slice(*variables)

        return @proc if values.empty?

        context = Context.new(@expression, values)

        lambda do |*args, **kwargs|
          context.instance_exec(*args, **kwargs, &@proc)
        end
      else
        @proc
      end
    end

    def to_s(as_block: false)
      if @parameters.empty?
        as_block ? "{ #{@expression} }" : "-> { #{@expression} }"
      else
        args = arg_list(substitutions: Expression.default_substitutions)
        as_block ? "{ |#{args}| #{@expression} }" : "->(#{args}) { #{@expression} }"
      end
    end
    alias inspect to_s

    private

    def arg_list(substitutions: nil)
      @parameters.map do |type, name|
        case type
        when :req, :opt
          substitutions&.[](name) || name
        when :key, :keyreq
          "#{name}:"
        end
      end.join(', ')
    end

    def evaluate(values)
      @expression.evaluate(**values)
    end
  end
end
