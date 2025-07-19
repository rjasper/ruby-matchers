# frozen_string_literal: true

module Matcher
  class InlineMatcher < Base
    def initialize(matcher = nil, negatable: false, negated: false, &block)
      raise 'no block given' unless block_given?

      super()

      @matcher = matcher
      @negated = negated
      @negatable = negatable
      @block = block
    end

    attr_reader :matcher, :negated

    public :expected, :report

    def ~
      return super unless @negatable

      InlineMatcher.new(@matcher&.~, negatable: @negatable, negated: !@negated, &@block)
    end

    def receiver
      @block.binding.receiver
    end

    def check(actual, &y)
      instance_exec(actual, y, &@block)
    end
    protected :check

    def to_s
      args = if @matcher
        "(#{@negated ? ~@matcher : @matcher})"
      else
        ''
      end

      "#{'~' if @negated}inline#{args} { #{Utils.block_location(@block)} }"
    end
  end

  module MatcherBuilding
    def inline(matcher = NULL, negatable: false, &)
      matcher = Matcher.null?(matcher) ? nil : Matcher.of(matcher)

      InlineMatcher.new(matcher, negatable:, &)
    end
  end
end
