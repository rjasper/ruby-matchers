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
      return Recorder.to_expression(obj) if Recorder.recorder?(obj)

      case obj
      when Base
        raise ArgumentError, 'Cannot use matcher as expression'
      when NoExpression
        raise ArgumentError, "Cannot use #{obj.class} as expression"
      when Expression
        obj
      when Array
        if obj.any? { expression_or_recorder?(_1) }
          items = obj.map { of(_1) }

          ArrayExpression.new(items)
        else
          Constant.new(obj)
        end
      when Hash
        if obj.any? { |k, v| expression_or_recorder?(k) || expression_or_recorder?(v) }
          pairs = obj.map do |key, value|
            [of(key), of(value)]
          end

          HashExpression.new(pairs)
        else
          Constant.new(obj)
        end
      when Range
        if expression_or_recorder?(obj.begin) || expression_or_recorder?(obj.end)
          RangeExpression.new(of(obj.begin), of(obj.end), obj.exclude_end?)
        else
          Constant.new(obj)
        end
      when Set
        if obj.any? { expression_or_recorder?(_1) }
          items = obj.map { of(_1) }

          SetExpression.new(items)
        else
          Constant.new(obj)
        end
      else
        Constant.new(obj)
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

    def visit
      return to_enum(:visit) unless block_given?

      yield self
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
