# frozen_string_literal: true

require 'singleton'

module Matcher
  class Builder
    include ExpressionBuilding

    def of(matcher)
      Matcher.of(matcher)
    end

    def satisfy(message = nil, &block)
      BlockMatcher.new(block, message)
    end

    def equal(value)
      EqualMatcher.new(value)
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

    def partial(hash)
      hash = hash.transform_values { of(_1) }
      HashMatcher.new(hash, partial: true)
    end

    def partial_r(hash)
      return of(hash) if ExpressionRecorder.recorder?(hash) || !hash.is_a?(Hash)

      hash = hash.transform_values { partial_r(_1) }
      HashMatcher.new(hash, partial: true)
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
