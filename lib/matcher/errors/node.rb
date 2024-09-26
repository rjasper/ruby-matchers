# frozen_string_literal: true

module Matcher
  module Errors
    class Node
      def valid?
        false
      end

      def inspect
        to_s
      end
    end
  end
end
