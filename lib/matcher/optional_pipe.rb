# frozen_string_literal: true

module Matcher
  class OptionalPipe
    include NoExpression
    include NoKey
    extend Forwardable

    def initialize(pipe, fallback)
      @pipe = pipe
      @fallback = fallback
    end

    def_delegator :@pipe, :^

    def ~
      OptionalPipe.new(~@pipe, @fallback)
    end

    def fallback
      @pipe ^ @fallback
    end
  end
end
