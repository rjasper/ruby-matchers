# frozen_string_literal: true

require 'singleton'

module Matcher
  class Builder
    def of(matcher)
      Matcher.of(matcher)
    end

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
      raise "constant and block given" if !Matcher.null?(constant) && block_given?

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
      @vars ||= VariableFactory.new
    end

    class VariableFactory
      def initialize
        @cache = {}
      end

      def [](symbol)
        variable = if Variable::WELL_KNOWN.include?(symbol)
          Variable.send(symbol)
        else
          @cache[symbol] ||= Variable.new(symbol)
        end

        ExpressionRecorder.new(variable)
      end
    end

    def setvar(assigns = nil, matcher = NULL, **kwargs)
      raise "Cannot set both assigns and kwargs" if assigns && !kwargs.empty?

      assigns = kwargs unless assigns

      return Pipe.new { setvar(assigns, _1) } if Matcher.null?(matcher)

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
        @options = {}
        @last_object_id = nil
        @last_matcher = nil
        @used = Set.new
      end

      def check
        target_set = @targets.keys.reject { _1.start_with?('~') }.to_set
        missing_targets = @used - target_set
        unused_refs = target_set - @used

        raise "undefined ref: #{missing_targets.join(', ')}" unless missing_targets.empty?
        raise "unused ref: #{unused_refs.join(', ')}" unless unused_refs.empty?
      end

      def [](key, cyclic: false)
        @used << key

        ReferenceMatcher.new(key, @targets, @options, cyclic:)
      end

      DEFAULT_OPTIONS = { cache: true }.freeze

      def []=(key, matcher_or_options, matcher = NULL)
        raise "Cannot reassign reference: #{key.inspect}" if @targets.key?(key)

        if Matcher.null?(matcher)
          options = DEFAULT_OPTIONS
          matcher = matcher_or_options
        else
          options = matcher_or_options.merge(cache: true) { |_k, l, r| l }
        end

        @last_object_id = matcher.object_id
        matcher = Matcher.of(matcher)
        @last_matcher = matcher
        @targets[key] = matcher
        @options[key] = options
      end
    end

    def project(recorder, matcher = NULL)
      return Pipe.new { project(recorder, _1) } if Matcher.null?(matcher)

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
      return Pipe.new { each(_1) } if Matcher.null?(matcher)

      EachMatcher.new(Matcher.of(matcher))
    end

    def each_pair(matcher = NULL)
      return Pipe.new { each_pair(_1) } if Matcher.null?(matcher)

      EachPairMatcher.new(Matcher.of(matcher))
    end

    def map(recorder, matcher = NULL)
      return Pipe.new { map(recorder, _1) } if Matcher.null?(matcher)

      expression = ExpressionRecorder.to_expression(recorder)
      matcher = Matcher.of(matcher)

      MapMatcher.new(expression, matcher)
    end

    def set(array)
      SetMatcher.new(array.map { Matcher.of(_1) })
    end

    def neg(matcher = NULL)
      return Pipe.new { neg(_1) } if Matcher.null?(matcher)

      ~Matcher.of(matcher)
    end

    def all(*matchers)
      AllMatcher.new(matchers.map { Matcher.of(_1) })
    end

    def any(*matchers)
      AnyMatcher.new(matchers.map { Matcher.of(_1) })
    end

    def imply(condition, matcher = NULL)
      return Pipe.new { imply(condition, _1) } if Matcher.null?(matcher)

      condition = Matcher.of(condition)
      matcher = Matcher.of(matcher)

      ImplyMatcher.new(condition, matcher)
    end

    def imply_one(*matchers, else: NULL)
      els = { else: }[:else]
      els = Matcher.null?(els) ? nil : Matcher.of(els)

      ImplyOneMatcher.new(matchers, else: els)
    end

    def present(matcher = NULL)
      return Pipe.new { present(_1) } if Matcher.null?(matcher)

      all(value.present?, matcher)
    end

    def iso8601(string_or_time = nil)
      Iso8601Matcher.new(string_or_time)
    end
  end
end
