# frozen_string_literal: true

module Matcher
  class Expression
    class ExpressionBuilder
      include ExpressionBuilding
    end

    def self.build(&)
      result = Matcher.with_build_session do
        ExpressionBuilder.new.instance_exec(&)
      end

      of(result)
    end

    def self.of(obj)
      return ExpressionRecorder.to_expression(obj) if ExpressionRecorder.recorder?(obj)

      case obj
      when Expression
        obj
      when Array
        if obj.any? { _1.is_a?(Expression) }
          items = obj.map { of(_1) }

          ArrayExpression.new(items)
        else
          Constant.new(obj)
        end
      when Hash
        if obj.any? { |k, v| k.is_a?(Expression) || v.is_a?(Expression) }
          pairs = obj.map do |key, value|
            [of(key), of(value)]
          end

          HashExpression.new(pairs)
        else
          Constant.new(obj)
        end
      else
        Constant.new(obj)
      end
    end

    def self.try_recorder(obj)
      return obj unless ExpressionRecorder.recorder?(obj)

      ExpressionRecorder.to_expression(obj)
    end

    def initialize
      raise 'abstract class' if instance_of?(Expression)
    end

    def evaluate_tree(values)
      [evaluate(values)]
    end

    def visit
      return to_enum(:visit) unless block_given?

      yield self
    end

    def inspect
      to_s
    end

    def to_recorder
      ExpressionRecorder.new(self)
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
