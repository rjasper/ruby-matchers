# frozen_string_literal: true

module Matcher
  ##
  # It's possible to build calls with a block:
  #
  #   exp = Matcher::Expression.build do
  #     _.map { |x| x * 2 }
  #   end
  #
  #   exp.evaluate(actual: [1, 2]) # => [2, 4]
  #
  # During build time the block acts like an expression builder
  # (e.g. like `Expression.build`), where its arguments are recorders. So the inside
  # of a block cannot be arbitrary but must follow the same rules as for building
  # other expressions.
  #
  #   # WRONG
  #   Matcher::Expression.build do
  #     _.map { |x| 2 * x } # cannot multiply 2 with a recorder
  #   end
  #
  # == Support for symbol procs
  #
  #   exp = Matcher::Expression.build do
  #     _.map(&:to_i)
  #   end
  #
  #   exp.evaluate(actual: ['1', '2']) # => [1, 2]
  #
  # @see ExpressionBuilding#pass_through_blocks
  class Block
    extend Compatibility

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

    def self.build(expression_cache: nil, &block)
      return SymbolProc.new(block) if
        block.parameters == [[:req], [:rest]] &&
          /\(&:(\w+[!?]?|".*")\)/.match?(block.to_s)

      parameters = block.parameters
      args = []
      kwargs = {}
      parameter_names = Set.new
      variable_object_ids = Set.new

      parameters.each do |type, name|
        parameter_names << name
        variable = Variable.cache(name, expression_cache:)
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
      expression = Expression.of(result, expression_cache:)

      return SymbolProc.new(expression.method) if
        args.length == 1 &&
          expression.is_a?(Call) &&
          expression.unary? &&
          expression.receiver == Recorder.to_expression(args[0])

      ExpressionWalker.each_variable(expression) do |variable|
        raise "parameter #{quote_method(variable.symbol)} shadows an outer variable" if
          parameter_names.include?(variable.symbol) &&
            !variable_object_ids.include?(variable.object_id)
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
        kwlist = @parameters.map { |_type, name| "#{name}:" }.join(", ")

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
        args = arg_list
        as_block ? "{ |#{args}| #{@expression} }" : "->(#{args}) { #{@expression} }"
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
      end.join(", ")
    end

    def evaluate(values)
      @expression.evaluate(**values)
    end
  end
end
