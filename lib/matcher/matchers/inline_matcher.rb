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

    def ~
      return super unless @negatable

      InlineMatcher.new(@matcher&.~, negatable: @negatable, negated: !@negated, &@block)
    end

    def receiver
      @block.binding.receiver
    end

    class InlineContext
      extend Forwardable

      def initialize(matcher, state, y)
        @matcher = matcher
        @state = state
        @yield = y
      end

      attr_reader :state

      def_delegators :@state, *State.public_instance_methods - Object.public_instance_methods - %i[result]
      def_delegators :@matcher, *InlineMatcher.public_instance_methods  - Object.public_instance_methods - %i[match check]

      def _yield(matcher, act = @state.actual, **values)
        @yield.call(matcher, act, **values)
      end
    end

    def check(state, &block)
      context = InlineContext.new(self, state, block)
      context.instance_exec(&@block)
    end

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
    def inline(matcher = UNDEFINED, negatable: false, &)
      matcher = Matcher.undefined?(matcher) ? nil : matcher_of(matcher)

      InlineMatcher.new(matcher, negatable:, &)
    end
  end
end
