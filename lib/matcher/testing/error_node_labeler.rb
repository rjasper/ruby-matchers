# frozen_string_literal: true

module Matcher
  module Testing
    class ErrorNodeLabeler
      def initialize(phrasing = nil)
        @phrasing = phrasing
        @label_count = 0
        @element_label_index = {}
        @group_label_index = {}
      end

      def label_tree(error)
        leaves = []

        [label_tree_helper(error, List.empty, leaves), leaves]
      end

      Leaf = Struct.new(:label, :path, :message) do
        def hash
          label
        end

        def eql?(other)
          label == other.label
        end
      end

      private

      def label_tree_helper(error, path, leaves)
        case error
        when Errors::Empty
          0
        when Errors::And, Errors::Or
          child_labels = error.nodes.map { label_tree_helper(_1, path, leaves) }
          group_label_for(error, child_labels.sort)
        when Errors::Nested
          label_tree_helper(error.node, path << error.key, leaves)
        when Errors::Element
          label = element_label_for(path, error)
          message = error.message
          message = @phrasing.call(path, message) if
            @phrasing && message.is_a?(Message)

          leaves << Leaf.new(label, path, message)

          label
        else
          raise "Unexpected error node: #{error.inspect}"
        end
      end

      def element_label_for(path, element)
        message = element.message
        message = @phrasing.call(path, message) if
          @phrasing && message.is_a?(Message)

        key = [path, message]

        @element_label_index[key] ||= (@label_count += 1)
      end

      def group_label_for(group, children_labels)
        key = [group.class, children_labels]

        @group_label_index[key] ||= (@label_count += 1)
      end
    end
  end
end
