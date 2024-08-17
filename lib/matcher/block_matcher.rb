# frozen_string_literal: true

module Matcher
  class BlockMatcher < Base
    def initialize(block, message = nil)
      super()

      @block = block
      @message = message
    end

    def check(actual, **)
      errors << message_for(actual) unless @block.call(actual, **)
    end

    def inspect
      @message || "-> { #{block_location} }"
    end

    private

    def message_for(actual)
      if @message
        "expected #{@message} but got #{actual}"
      else
        "expected to satisfy condition #{block_location} but got #{actual}"
      end
    end

    def block_location
      file, line = @block.source_location

      "#{File.basename(file)}:#{line}"
    end
  end
end
