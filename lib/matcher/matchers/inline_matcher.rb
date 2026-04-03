# frozen_string_literal: true

module Matcher
  class InlineMatcher < Base
    def initialize(matcher = nil, negatable: false, negated: false, &block)
      raise "no block given" unless block_given?

      super()

      @matcher = matcher
      @negated = negated
      @negatable = negatable
      @block = block
    end

    attr_reader :matcher, :negated

    def negate
      return super unless @negatable

      InlineMatcher.new(
        @matcher&.~, negatable: @negatable, negated: !@negated, &@block
      )
    end

    def receiver
      @block.binding.receiver
    end

    class InlineContext
      extend Forwardable

      def initialize(matcher, state, block)
        @matcher = matcher
        @state = state
        @block = block
      end

      attr_reader :state

      def_delegators :@state, *State.public_instance_methods(false) - %i[result]
      def_delegators :@matcher, :receiver, :matcher, :negated

      def _yield(matcher, act = @state.actual, **values)
        @block.call(matcher, act, **values)
      end
    end

    def validate(state, &block)
      context = InlineContext.new(self, state, block)
      context.instance_exec(&@block)
    end

    def to_s
      args = if @matcher
        "(#{@negated ? ~@matcher : @matcher})"
      else
        ""
      end

      "#{'~' if @negated}inline#{args} { #{Utils.block_location(@block)} }"
    end
  end

  module MatcherBuilding
    ##
    # Creates an anonymous custom matcher
    #
    # If you need more control to define your matching logic then +inline+
    # may give you an alternative to implementing a new matcher class. Within
    # the +inline+ block you have direct access to +actual+, +errors+, +_yield+
    # and other state methods.
    #
    # @example
    #   # matches distinct arrays
    #   inline do
    #     indices = Hash.new
    #
    #     actual.each_with_index do |e, i|
    #       if (original_index = indices[e])
    #         errors[i] << expected.not.duplicate(original_index)
    #       else
    #         indices[e] = i
    #       end
    #     end
    #   end
    #
    # @param matcher [Base] optionaly provide a child matcher. Call the matcher
    #   with +_yield matcher, actual, **values+
    # @param negatable [true, false] set to true if your matching logic respects
    #   the negated flag. Otherwise, the default negation implementation is
    #   used. When +negated = true+ the child matcher is automatically negated.
    # @yield inline context
    # @return [InlineMatcher]
    def inline(matcher = UNDEFINED, negatable: false, &)
      matcher = Matcher.undefined?(matcher) ? nil : matcher_of(matcher)

      InlineMatcher.new(matcher, negatable:, &)
    end
  end
end
