# frozen_string_literal: true

module Matcher
  module Testing
    class ErrorBuilder
      def self.build(&)
        nodes = build_nodes(&)

        AndError.from(nodes)
      end

      def self.build_nodes(&)
        builder = ErrorBuilder.new
        builder.instance_exec(&)
        builder.nodes
      end

      attr_reader :nodes

      def initialize
        @nodes = []
      end

      def _or(*path, &)
        nodes = ErrorBuilder.build_nodes(&)
        node = OrError.from(nodes)

        @nodes << nest(path, node)
      end

      def _and(*path, &)
        nodes = ErrorBuilder.build_nodes(&)
        node = AndError.from(nodes)

        @nodes << nest(path, node)
      end

      def error(path_or_message, message = nil)
        if message.nil?
          @nodes << ElementError.new(path_or_message)
        else
          path = Array(path_or_message)
          element = ElementError.new(message)

          @nodes << nest(path, element)
        end
      end

      private

      def nest(path, node)
        path.reverse_each.reduce(node) { NestedError.from(_2, _1) }
      end
    end
  end
end
