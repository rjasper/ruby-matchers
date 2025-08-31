# frozen_string_literal: true

module Matcher
  class Expression
    class ExpressionBuilder
      include ExpressionBuilding

      def initialize(build_session: Matcher.build_session)
        ExpressionBuilding.init(self, build_session)
      end
    end

    def self.build(&)
      Matcher.with_build_session do |build_session|
        builder = ExpressionBuilder.new(build_session:)
        result = builder.instance_exec(&)
        builder.expression_of(result)
      end
    end

    def self.of(obj, expression_cache: nil)
      expression = case obj
      when -> { Recorder.recorder?(_1) }
        Recorder.to_expression(obj)
      when Base
        raise ArgumentError, 'Cannot use matcher as expression'
      when NoExpression
        raise ArgumentError, "Cannot use #{obj.class} as expression"
      when Proc
        raise ArgumentError, "Cannot use Proc as expression. Use `expr { ... }' instead"
      when Expression
        obj
      when Array
        if obj.any? { expression_or_recorder?(_1) }
          items = obj.map { of(_1, expression_cache:) }

          ArrayExpression.new(items)
        else
          Constant.new(obj)
        end
      when Hash
        if obj.any? { |k, v| expression_or_recorder?(k) || expression_or_recorder?(v) }
          pairs = obj.map do |key, value|
            [of(key, expression_cache:), of(value, expression_cache:)]
          end

          HashExpression.new(pairs)
        else
          Constant.new(obj)
        end
      when Range
        if expression_or_recorder?(obj.begin) || expression_or_recorder?(obj.end)
          begin_expr = of(obj.begin, expression_cache:)
          end_expr = of(obj.end, expression_cache:)

          RangeExpression.new(begin_expr, end_expr, obj.exclude_end?)
        else
          Constant.new(obj)
        end
      when Set
        if obj.any? { expression_or_recorder?(_1) }
          items = obj.map { of(_1, expression_cache:) }

          SetExpression.new(items)
        else
          Constant.new(obj)
        end
      else
        Constant.new(obj)
      end

      expression_cache ? expression_cache[expression] : expression
    end

    def self.current_cache(build_session = Matcher.build_session)
      build_session[:_expression_cache] ||= ExpressionCache.new if build_session
    end

    def self.try_recorder(obj)
      return obj unless Recorder.recorder?(obj)

      Recorder.to_expression(obj)
    end

    def self.expression_or_recorder?(obj)
      Recorder.recorder?(obj) || obj.is_a?(Expression)
    end

    def initialize
      raise 'abstract class' if instance_of?(Expression)
    end

    def evaluate_tree(values)
      [evaluate(values)]
    end

    def given_for(values)
      variables.each_with_object({}) do |symbol, given|
        given[symbol] = values[symbol]
      end
    end

    def visit
      return to_enum(:visit) unless block_given?

      yield self
    end

    def free_symbol(symbol)
      parameters = ExpressionWalker.each_block(self).flat_map do |block|
        block.parameters.map { |_type, name| name }
      end

      identifiers = (variables + parameters).to_set

      return symbol unless identifiers.include?(symbol)

      i = 2
      loop do
        symbol_i = :"#{symbol}#{i}"

        return symbol_i unless identifiers.include?(symbol_i)

        i += 1
      end
    end

    def inspect
      to_s
    end

    def to_recorder
      Recorder.new(self)
    end

    def self.with_substitutions(**substitutions)
      Thread.current[:matcher_expression_substitutions] = substitutions

      yield
    ensure
      Thread.current[:matcher_expression_substitutions] = nil
    end

    def self.default_substitutions
      Thread.current[:matcher_expression_substitutions] ||
        { actual: '_', key: 'k', value: 'v', index: 'i' }
    end
  end
end
