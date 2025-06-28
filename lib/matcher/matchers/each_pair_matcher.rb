# frozen_string_literal: true

module Matcher
  class EachPairMatcher < Base
    def initialize(matcher, key: :key, value: :value, parent: :parent)
      super()

      @matcher = matcher
      @key = key
      @value = value
      @parent = parent
    end

    def ~
      NegatedEachPairMatcher.new(@matcher, key: @key, value: @value, parent: @parent)
    end

    def check(actual)
      unless actual.respond_to?(:each_pair)
        errors << expected.responding_to(:each_pair)
        return
      end

      actual.each_pair do |key, value|
        errors[key] << yield(
          @matcher,
          [key, value],
          @key => key,
          @value => value,
          @parent => actual
        )
      end
    end
    protected :check

    def to_s
      "each_pair(#{@matcher})"
    end
  end

  module MatcherBuilding
    def each_pair(matcher = NULL)
      return Pipe.new { each_pair(_1) } if Matcher.null?(matcher)

      EachPairMatcher.new(Matcher.of(matcher))
    end

    def each_key(matcher = NULL)
      return Pipe.new { each_key(_1) } if Matcher.null?(matcher)

      key = Variable.new(:key)
      matcher = Matcher.of(matcher)

      EachPairMatcher.new(
        ProjectMatcher.new(key, matcher),
      )
    end

    def each_value(matcher = NULL)
      return Pipe.new { each_value(_1) } if Matcher.null?(matcher)

      assigns = { actual: ->(value:) { value } }
      matcher = Matcher.of(matcher)

      EachPairMatcher.new(
        SetVariablesMatcher.new(assigns, matcher),
      )
    end
  end
end
