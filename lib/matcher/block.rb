    # frozen_string_literal: true

module Matcher
  class Block
    DEFAULT_CONTEXT = lambda do |expression, values|
      Context.new(expression, values)
    end

    class Context
      def initialize(block, values)
        @expression = block.expression
        @values = values
      end

      def evaluate(values)
        values.merge!(@values) { |_k, _l, r| r } if @values

        @expression.evaluate(values)
      end
    end

    def self.build(context: DEFAULT_CONTEXT, &block)
      parameters = block.parameters
      args = []
      kwargs = {}

      parameters.each do |type, name|
        recorder = ExpressionRecorder.new(Variable.new(name))

        case type
        when :req, :opt
          args << recorder
        when :key, :keyreq
          kwargs[name] = recorder
        when :rest
          raise "*#{name unless name == :*} not allowed"
        when :keyrest
          raise "**#{name unless name == :**} not allowed"
        when :block
          raise "&#{name unless name == :&} not allowed"
        end
      end

      result = block.call(*args, **kwargs)

      expression = if ExpressionRecorder.recorder?(result)
        ExpressionRecorder.to_expression(result)
      else
        Constant.new(result)
      end

      new(parameters, expression, context:)
    end

    attr_reader :parameters, :expression, :context

    def initialize(parameters, expression, context: DEFAULT_CONTEXT)
      @parameters = parameters
      @expression = expression
      @context = context
    end

    def ==(other)
      return true if equal?(other)
      return false unless other.instance_of?(Block)

      @parameters.eql?(other.parameters) && @expression == other.expression
    end
    alias eql? ==

    def hash
      [@parameters, @expression].hash
    end

    def variables
      @variables ||= @expression.variables - @parameters.map { _2 }
    end

    def to_proc(values: nil)
      @proc ||= begin
        kwlist = @parameters.map { |_type, name| "#{name}:" }.join(', ')

        instance_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          ->(#{arg_list}) { evaluate({ #{kwlist} }) }                           # ->(arg, kwarg:) { evaluate({ arg:, kwarg: }) }
        RUBY
      end

      if @context
        context = @context.call(self, values)

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
        as_block ? "{ |#{arg_list}| #{@expression} }" : "->(#{arg_list}) { #{@expression} }"
      end
    end
    alias inspect to_s

    private

    def arg_list
      @parameters.map do |type, name|
        case type
        when :req, :opt
          name
        when :key, :keyreq
          "#{name}:"
        end
      end.join(', ')
    end
  end
end
