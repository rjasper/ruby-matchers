# frozen_string_literal: true

module Matcher
  module Errors
    class Element < Node
      attr_reader :message

      def initialize(message)
        @message = message
      end

      def ==(other)
        return true if equal?(other)

        other.is_a?(Element) && @message == other.message
      end

      def &(other)
        And.new([self, other])
      end

      def |(other)
        Or.new([self, other])
      end
    end
  end
end
