# frozen_string_literal: true

module Matcher
  class MapMatcher < Base
    def initialize(projection, matcher, index: :index, original: :original)
      super()

      @projection = projection
      @matcher = matcher
      @index = index
      @original = original
    end

    def ~
      NegatedMapMatcher.new(@projection, @matcher, index: @index, original: @original)
    end

    def check(actual)
      unless actual.respond_to?(:map)
        errors << expected.responding_to(:map)
        return
      end

      mapped = []
      mapping_failed = false

      actual.map.with_index do |item, i|
        mapped << @projection.evaluate(
          values.merge(actual: item, @index => i, @original => actual),
        )
      rescue Call::Error => e
        errors[i] << e.message_for_errors
        mapping_failed = true
      end

      return if mapping_failed

      mapped_errors = yield @matcher, mapped, @original => actual

      errors << map_errors(mapped_errors)
    end
    protected :check

    def to_s
      "map(#{@projection}, #{@matcher})"
    end

    class MapContextFactory
      attr_reader :index

      def initialize(index)
        @index = index
      end

      def create(block, values)
        MapContext.new(block, values, @index)
      end

      def ==(other)
        return true if equal?(other)

        other.instance_of?(MapContextFactory) &&
          @index.eql?(other.index)
      end
      alias eql? ==

      def hash
        @index.hash
      end
    end

    class MapContext < Block::Context
      attr_reader :index

      def initialize(block, values, index)
        super(block, values)

        @index = index
        @counter = 0
      end

      def evaluate(values)
        values[@index] = @counter
        result = super
        @counter += 1

        result
      end
    end

    module ErrorMapping
      private

      def map_errors(node)
        case node
        when EmptyError
          node
        when AndError, OrError
          children = node.nodes.map { map_errors(_1) }
          node.class.new(children)
        when NestedError
          key = node.key

          is_index = key.is_a?(Call) &&
            key.binary? &&
            key.receiver == Variable.actual &&
            (operand = key.args[0]) &&
            operand.is_a?(Constant) &&
            operand.constant.is_a?(Integer)

          if is_index
            nested_projection = NestedError.from(@projection, node.node)
            NestedError.from(key, nested_projection)
          else
            node
          end
        when ElementError
          NestedError.from(nested_key, node)
        else
          raise "Unexpected node: #{node.inspect}"
        end
      end

      def nested_key
        proj = @projection
        actual_var = Variable.actual

        as_symbol_proc = proj.is_a?(Call) && proj.unary? && proj.receiver == actual_var

        block = if as_symbol_proc
          SymbolProc.new(proj.method)
        else
          symbol = find_free_symbol(proj)
          parameters = [[:opt, symbol]]
          expression = proj.substitute(actual: symbol, @original => :actual)
          free_variables = expression.variables - [symbol]

          context = if free_variables.include?(@index)
            MapContextFactory.new(@index)
          elsif !free_variables.empty?
            Block::ContextFactory.instance
          end

          Block.new(parameters, expression, context:)
        end

        Call.new(actual_var, :map, [], {}, block)
      end

      def find_free_symbol(expression)
        parameters = ExpressionWalker.each_block(expression).flat_map do |block|
          block.parameters.map { |_type, name| name }
        end

        identifiers = (expression.variables + parameters).to_set(&:to_s)

        return :e unless identifiers.include?('e')

        i = 2
        loop do
          name = "e#{i}"

          return name.to_sym unless identifiers.include?(name)

          i += 1
        end
      end
    end

    include ErrorMapping
  end

  module MatcherBuilding
    def map(recorder, matcher = NULL)
      return Pipe.new { map(recorder, _1) } if Matcher.null?(matcher)

      expression = ExpressionRecorder.to_expression(recorder)
      matcher = Matcher.of(matcher)

      MapMatcher.new(expression, matcher)
    end
  end
end
