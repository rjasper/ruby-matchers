# frozen_string_literal: true

module Matcher
  class Expression
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

    def inspect
      to_s
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
