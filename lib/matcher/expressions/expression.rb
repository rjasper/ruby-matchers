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

    def self.expression_or_value(obj, expression_cache: nil)
      case obj
      when -> { Recorder.recorder?(_1) }
        return Recorder.to_expression(obj)
      when Base
        raise ArgumentError, 'Cannot use matcher as expression'
      when NoExpression
        raise ArgumentError, "Cannot use #{obj.class} as expression"
      when Proc
        raise ArgumentError, "Cannot use Proc as expression. Use `expr { ... }' instead"
      when Array
        items = obj.map { expression_or_value(_1, expression_cache:) }

        if items.any? { _1.is_a?(Expression) }
          items.each_with_index do |item, i|
            items[i] = Constant.cache(item, expression_cache) unless item.is_a?(Expression)
          end

          return ArrayExpression.new(items)
        end
      when Hash
        pairs = obj.map do |key, value|
          key = expression_or_value(key, expression_cache:)
          value = expression_or_value(value, expression_cache:)

          [key, value]
        end

        if pairs.any? { |k, v| k.is_a?(Expression) || v.is_a?(Expression) }
          pairs.each do |pair|
            k, v = pair

            pair[0] = Constant.cache(k, expression_cache) unless k.is_a?(Expression)
            pair[1] = Constant.cache(v, expression_cache) unless v.is_a?(Expression)
          end

          return HashExpression.new(pairs)
        end
      when Range
        from = expression_or_value(obj.begin, expression_cache:)
        to = expression_or_value(obj.end, expression_cache:)

        if from.is_a?(Expression) || to.is_a?(Expression)
          from = Constant.cache(from, expression_cache) unless from.is_a?(Expression)
          to = Constant.cache(to, expression_cache) unless to.is_a?(Expression)

          return RangeExpression.new(from, to, obj.exclude_end?)
        end
      when Set
        items = obj.map { expression_or_value(_1, expression_cache:) }

        if items.any? { _1.is_a?(Expression) }
          items.each_with_index do |item, i|
            items[i] = Constant.cache(item, expression_cache) unless item.is_a?(Expression)
          end

          return SetExpression.new(items)
        end
      end

      obj
    end

    def self.of(obj, expression_cache: nil)
      obj = expression_or_value(obj, expression_cache:)

      if obj.is_a?(Expression)
        obj
      else
        Constant.cache(obj, expression_cache)
      end
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
