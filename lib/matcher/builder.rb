# frozen_string_literal: true

module Matcher
  class Builder
    delegate :of, to: :Matcher

    def satisfy(message = nil, &block)
      BlockMatcher.new(block, message)
    end

    def equal(value)
      EqualMatcher.new(value)
    end

    def declare(*symbols)
      conflicts = symbols & methods

      raise "Cannot declare these variables: #{conflicts.join(', ')}" if conflicts.length > 1
      raise "Cannot declare variable \"#{conflicts[0]}\"" if conflicts.length == 1

      symbols.each do |symbol|
        define_singleton_method(symbol) do
          vars[symbol]
        end
      end
    end

    def expr(constant = NULL, to_s: false, &)
      raise "constant and block given" if !null?(constant) && block_given?

      expression = if block_given?
        BlockExpression.new(to_s:, &)
      else
        Constant.new(constant)
      end

      ExpressionRecorder.new(expression)
    end

    def expr_s(constant = NULL, &)
      expr(constant, to_s: true, &)
    end

    def actual
      vars[:actual]
    end
    alias _ actual

    def key
      vars[:key]
    end
    alias k key

    def value
      vars[:value]
    end
    alias v value

    def index
      vars[:index]
    end
    alias i index

    def parent
      vars[:parent]
    end

    def original
      vars[:original]
    end

    def logical_operators(&)
      Matcher.with_settings(logical_operators: true, &)
    end
    alias lo logical_operators

    def assign
      value = ExpressionRecorder.transform(yield)

      call = Call.last_assign
      Call.reset_last_assign

      raise "Could not return last assignment" if
        !call&.binary? || !call.args[0].equal?(value)

      call
    end

    def vars
      VariableFactory.instance
    end

    class VariableFactory
      include Singleton

      def [](symbol)
        variable = Variable.new(symbol)

        ExpressionRecorder.new(variable)
      end
    end

    def setvar(assigns = nil, matcher = NULL, **kwargs)
      raise "Cannot set both assigns and kwargs" if assigns && !kwargs.empty?

      assigns = kwargs unless assigns

      return Pipe.new { setvar(assigns, _1) } if null?(matcher)

      matcher = Matcher.of(matcher)

      SetVariablesMatcher.new(assigns, matcher)
    end

    def refs?
      !@refs.nil?
    end

    def refs
      @refs ||= ReferenceCollection.new
    end

    class ReferenceCollection
      attr_reader :last_object_id, :last_matcher

      def initialize
        @targets = {}
        @last_object_id = nil
        @last_matcher = nil
        @used = Set.new
      end

      def check
        target_set = @targets.keys.to_set
        missing_targets = @used - target_set
        unused_refs = target_set - @used

        raise "undefined ref: #{missing_targets.join(', ')}" unless missing_targets.empty?
        raise "unused ref: #{unused_refs.join(', ')}" unless unused_refs.empty?
      end

      def [](key, cyclic: false)
        @used << key

        ReferenceMatcher.new(@targets, key, cyclic:)
      end

      def []=(key, matcher)
        raise "Cannot reassign reference: #{key.inspect}" if @targets.key?(key)

        @last_object_id = matcher.object_id
        matcher = Matcher.of(matcher)
        @last_matcher = matcher
        @targets[key] = matcher
      end
    end

    def project(recorder, matcher = NULL)
      return Pipe.new { project(recorder, _1) } if null?(matcher)

      expression = ExpressionRecorder.to_expression(recorder)
      matcher = Matcher.of(matcher)

      ProjectMatcher.new(expression, matcher)
    end

    def all_entries(hash)
      Matcher.with_settings(all_entries: true) do
        Matcher.of(hash)
      end
    end

    def partial_entries(hash)
      Matcher.with_settings(all_entries: false) do
        Matcher.of(hash)
      end
    end

    def each(matcher = NULL)
      return Pipe.new { each(_1) } if null?(matcher)

      EachMatcher.new(Matcher.of(matcher))
    end

    def map(recorder, matcher = NULL)
      return Pipe.new { map(recorder, _1) } if null?(matcher)

      expression = ExpressionRecorder.to_expression(recorder)
      matcher = Matcher.of(matcher)

      MapMatcher.new(expression, matcher)
    end

    def set(array)
      SetMatcher.new(array.map { Matcher.of(_1) })
    end

    def all(*matchers)
      AllMatcher.new(matchers.map { Matcher.of(_1) })
    end

    def any(*matchers)
      AnyMatcher.new(matchers.map { Matcher.of(_1) })
    end

    def imply(condition, matcher = NULL)
      return Pipe.new { imply(condition, _1) } if null?(matcher)

      condition = Matcher.of(condition)
      matcher = Matcher.of(matcher)

      ImplyMatcher.new(condition, matcher)
    end

    def imply_one(*matchers)
      ImplyOneMatcher.new(matchers)
    end

    def present(matcher = NULL)
      return Pipe.new { present(_1) } if null?(matcher)

      all(value.present?, matcher)
    end

    def iso8601(string_or_time = nil)
      Iso8601Matcher.new(string_or_time)
    end

    private

    def null?(object)
      !ExpressionRecorder.recorder?(object) && object.equal?(NULL)
    end
  end
end
