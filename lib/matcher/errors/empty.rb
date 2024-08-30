# frozen_string_literal: true

module Matcher
  module Errors
    class Empty < Node
      include Singleton

      def &(other)
        other
      end

      def |(other)
        other
      end

      def valid?
        true
      end
    end
  end
end
