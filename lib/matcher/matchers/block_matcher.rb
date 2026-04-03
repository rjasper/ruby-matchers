# frozen_string_literal: true

module Matcher
  class BlockMatcher < Base
    def initialize(block, description = nil, negated: false)
      super()

      @block = block
      @description = description
      @negated = negated
    end

    def negate
      BlockMatcher.new(@block, @description, negated: !@negated)
    end

    def validate(state)
      result = Utils.call_block(@block, state.values)

      state.errors << build_message(state) if @negated ^ !result
    end

    def to_s
      string = @description || "-> { #{block_location} }"

      if @negated
        "neg(#{string})"
      else
        string
      end
    end

    private

    def build_message(state)
      if @description
        state.expected.not_if(@negated)
          .described_by(@description)
      else
        state.expected.namespace(:block).not_if(@negated)
          .satisfied(block_location)
      end
    end

    def block_location
      Utils.block_location(@block)
    end
  end

  module MatcherBuilding
    ##
    # Matches when block returns truthy
    # @example
    #   satisfy('an even number') { |actual:| actual.even? }
    # @param message [String, nil] optional description for error reporting
    # @return [BlockMatcher]
    def satisfy(message = nil, &block)
      BlockMatcher.new(block, message)
    end
  end
end
