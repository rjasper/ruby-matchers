# frozen_string_literal: true

module Matcher
  module Errors
    class Node
      def &(other)
        case other
        when Empty
          self
        when And
          And.new([self].concat(other.nodes))
        else
          And.new([self, other])
        end
      end

      def |(other)
        case other
        when Empty
          self
        when Or
          Or.new([self].concat(other.nodes))
        else
          Or.new([self, other])
        end
      end

      def valid?
        false
      end

      def inspect
        to_s
      end
    end
  end
end
