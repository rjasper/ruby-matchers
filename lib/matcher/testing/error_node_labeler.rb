# frozen_string_literal: true

module Matcher
  module Testing
    class ErrorNodeLabeler
      def initialize
        @label_count = 0
        @element_label_index = {}
        @group_label_index = {}
      end

      def label_tree(error)
        leaves = []

        [label_tree_helper(error, nil, leaves), leaves]
      end

      List = Struct.new(:head, :tail) do
        def hash
          @hash ||= [head, tail.hash].hash
        end

        def eql?(other)
          head.eql?(other.head) && tail.eql?(other.tail)
        end

        def reverse_each(&)
          tail&.reverse_each(&)
          yield head
        end
      end

      Leaf = Struct.new(:label, :path, :element) do
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
          label_tree_helper(error.node, List.new(error.key, path), leaves)
        when Errors::Element
          label = element_label_for(path, error)
          leaves << Leaf.new(label, path, error)

          label
        else
          raise "Unexpected error node: #{error.inspect}"
        end
      end

      def element_label_for(path, element)
        key = [path, element.message]

        @element_label_index[key] ||= (@label_count += 1)
      end

      def group_label_for(group, children_labels)
        key = [group.class, children_labels]

        @group_label_index[key] ||= (@label_count += 1)
      end
    end
  end
end
