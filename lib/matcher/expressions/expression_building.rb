# frozen_string_literal: true

module Matcher
  module ExpressionBuilding
    ##
    # Builds an expression conveniently using {Recorder} and helpers from
    # {ExpressionDsl}.
    #
    # @example
    #   Matcher::Expression.build do
    #     _.sum(&:to_i)
    #   end
    #
    #   Matcher::Expression.build do
    #     range(vars[:from], vars[:to]).include?(_)
    #   end
    #
    # @see ExpressionDsl
    def build(&)
      Matcher.with_build_session do |build_session|
        builder = ExpressionBuilder.new(build_session:)
        result = builder.instance_exec(&)
        builder.expression_of(result)
      end
    end

    def expression_or_value(obj, expression_cache: nil)
      case obj
      when -> { Recorder.recorder?(_1) }
        return Recorder.to_expression(obj)
      when Base
        raise ArgumentError, "Cannot use matcher as expression"
      when NoExpression
        raise ArgumentError, "Cannot use #{obj.class} as expression"
      when Proc
        raise ArgumentError, "Cannot use Proc as expression. " \
          "Use `expr { ... }' instead"
      when Array
        items = obj.map { expression_or_value(_1, expression_cache:) }

        if items.any?(Expression)
          items.each_with_index do |item, i|
            unless item.is_a?(Expression)
              items[i] = Constant.cache(item, expression_cache)
            end
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

            unless k.is_a?(Expression)
              pair[0] = Constant.cache(k, expression_cache)
            end
            unless v.is_a?(Expression)
              pair[1] = Constant.cache(v, expression_cache)
            end
          end

          return HashExpression.new(pairs)
        end
      when Range
        from = expression_or_value(obj.begin, expression_cache:)
        to = expression_or_value(obj.end, expression_cache:)

        if from.is_a?(Expression) || to.is_a?(Expression)
          unless from.is_a?(Expression)
            from = Constant.cache(from, expression_cache)
          end
          to = Constant.cache(to, expression_cache) unless to.is_a?(Expression)

          return RangeExpression.new(from, to, exclude_end: obj.exclude_end?)
        end
      when Set
        items = obj.map { expression_or_value(_1, expression_cache:) }

        if items.any?(Expression)
          items.each_with_index do |item, i|
            unless item.is_a?(Expression)
              items[i] = Constant.cache(item, expression_cache)
            end
          end

          return SetExpression.new(items)
        end
      end

      obj
    end

    def of(obj, expression_cache: nil)
      obj = expression_or_value(obj, expression_cache:)

      if obj.is_a?(Expression)
        obj
      else
        Constant.cache(obj, expression_cache)
      end
    end

    def try_recorder(obj)
      return obj unless Recorder.recorder?(obj)

      Recorder.to_expression(obj)
    end
  end
end
