# frozen_string_literal: true

module Matcher
  class ElementError < Error
    attr_reader :message

    def initialize(message)
      super()

      @message = message
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(ElementError) &&
        @message == other.message
    end

    def to_s
      @message.inspect
    end
  end
end
