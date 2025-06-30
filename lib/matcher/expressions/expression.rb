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
        items = obj.map { of(_1) }

        ArrayExpression.new(items)
      else
        Constant.new(obj)
      end
    end

    def self.negate(obj)
      if obj.is_a?(Expression)
        obj.negated
      else
        !obj
      end
    end

    def initialize
      raise 'abstract class' if instance_of?(Expression)
    end

    def negated
      Call.new(self, :!)
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
