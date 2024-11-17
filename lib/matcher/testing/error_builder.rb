# frozen_string_literal: true

module Matcher
  module Testing
    class ErrorBuilder
      def self.build(&)
        nodes = build_nodes(&)

        Errors::And.from(nodes)
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
        node = Errors::Or.from(nodes)

        @nodes << nest(path, node)
      end

      def _and(*path, &)
        nodes = ErrorBuilder.build_nodes(&)
        node = Errors::And.from(nodes)

        @nodes << nest(path, node)
      end

      def error(path_or_message, message = nil)
        if message.nil?
          @nodes << Errors::Element.new(path_or_message)
        else
          path = Array(path_or_message)
          element = Errors::Element.new(message)

          @nodes << nest(path, element)
        end
      end

      private

      def nest(path, node)
        path.reverse_each.reduce(node) { Errors::Nested.from(_2, _1) }
      end
    end
  end
end
