# frozen_string_literal: true

module Matcher
  module Errors
    class Collector
      def self.error_from(obj)
        case obj
        when String
          Errors::Element.new(obj)
        when Errors::Node
          obj
        else
          "Unexpected error object: #{obj.inspect}"
        end
      end

      attr_reader :node

      def initialize
        @node = Empty.instance
      end

      class Brackets
        def initialize(parent, key)
          @parent = parent
          @key = key
        end

        def <<(node)
          node = Collector.error_from(node)

          @parent << Nested.from(@key, node)
        end

        def [](key)
          Brackets.new(self, key)
        end
      end

      def <<(node)
        return if node.is_a?(Empty)

        node = Collector.error_from(node)

        case @node
        when Empty
          @node = node
        when And
          @node << node
        else
          @node &= node
        end
      end

      def [](key)
        Brackets.new(self, key)
      end

      def clear
        @node = Empty.instance
      end
    end
  end
end
