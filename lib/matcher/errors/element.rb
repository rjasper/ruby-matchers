# frozen_string_literal: true

module Matcher
  module Errors
    class Element < Node
      attr_reader :message

      def initialize(message)
        super()

        @message = message
      end

      def ==(other)
        return true if equal?(other)

        other.instance_of?(Element) &&
          @message == other.message
      end

      def &(other)
        return self if other.is_a?(Empty)

        And.new([self, other])
      end

      def |(other)
        return self if other.is_a?(Empty)

        Or.new([self, other])
      end

      def to_s
        @message.inspect
      end
    end
  end
end
