# frozen_string_literal: true

module Matcher
  class BlockMatcher < Base
    def initialize(block, message = nil, negated: false)
      super()

      @block = block
      @message = message
      @negated = negated
    end

    def negated
      BlockMatcher.new(@block, @message, negated: !@negated)
    end

    def check(actual:, **)
      errors << message_for(actual) if @negated ^ !@block.call(actual, **)
    end
    protected :check

    def inspect
      message = @message || "-> { #{block_location} }"

      if @negated
        "neg(#{message})"
      else
        message
      end
    end

    private

    def message_for(actual)
      expected = @negated ? 'did not expect' : 'expected'

      if @message
        "#{expected} #{@message} but got #{actual.inspect}"
      else
        "#{expected} to satisfy condition #{block_location} but got #{actual.inspect}"
      end
    end

    def block_location
      file, line = @block.source_location

      "#{File.basename(file)}:#{line}"
    end
  end
end
