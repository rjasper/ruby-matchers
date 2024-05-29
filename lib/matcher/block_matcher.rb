# frozen_string_literal: true

module Matcher
  class BlockMatcher < Base
    def initialize(block, message = nil)
      super()

      @block = block
      @message = message
    end

    def check(actual)
      errors << message_for(actual) unless @block.call(actual)
    end

    private

    def message_for(actual)
      if @message
        "expected #{@message} but got #{actual}"
      else
        "expected to satisfy condition but got #{actual}"
      end
    end
  end
end
