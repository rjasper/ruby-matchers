# frozen_string_literal: true

module Matcher
  class BlockMatcher < Base
    def initialize(block, description = nil, negated: false)
      super()

      @block = block
      @description = description
      @negated = negated
    end

    def ~
      BlockMatcher.new(@block, @description, negated: !@negated)
    end

    def check(actual)
      errors << build_message if @negated ^ !@block.call(actual, **values)
    end
    protected :check

    def to_s
      string = @description || "-> { #{block_location} }"

      if @negated
        "neg(#{string})"
      else
        string
      end
    end

    private

    def build_message
      if @description
        expected.not_if(@negated).described_by(@description)
      else
        expected(namespace: :block).not_if(@negated).satisfied(block_location)
      end
    end

    def block_location
      file, line = @block.source_location

      "#{File.basename(file)}:#{line}"
    end
  end
end
