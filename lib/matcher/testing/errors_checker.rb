# frozen_string_literal: true

module Matcher
  module Testing
    class ErrorsChecker
      def self.check(expected, actual, phrasing: nil)
        new(phrasing).check(expected, actual)
      end

      def initialize(phrasing = nil)
        @phrasing = phrasing
      end

      def check(expected, actual)
        labeler = ErrorNodeLabeler.new(@phrasing)
        expected = normalize(expected)
        actual = normalize(actual)
        expected_label, expected_leaves = labeler.label_tree(expected)
        actual_label, actual_leaves = labeler.label_tree(actual)

        return if expected_label == actual_label

        missing_messages = [
          missing_message('missing', expected_leaves - actual_leaves),
          missing_message('extra', actual_leaves - expected_leaves),
        ].compact.join("\n")

        return missing_messages unless missing_messages.empty?

        reporter = Reporter.new

        <<~TEXT
          expected:

          #{reporter.report(expected).chomp}

          but got:

          #{reporter.report(actual).chomp}
        TEXT
      end

      private

      def normalize(node, path = nil)
        case node
        when Errors::Empty
          node
        when Errors::And, Errors::Or
          children = node.nodes.map { normalize(_1) }

          if node.nodes.lazy.zip(children).all? { _1.equal?(_2) }
            node
          else
            node.class.new(children)
          end
        when Errors::Element
          path ? Errors::Nested.from(path, node) : node
        when Errors::Nested
          key = path ? key.new_root(path) : key

          normalize(node.node, key)
        else
          raise "Unexpected node: #{node.inspect}"
        end
      end

      def missing_message(prefix, missing)
        return nil if missing.empty?

        if missing.length == 1
          "#{prefix} error: #{message_for(missing[0])}"
        else
          "#{prefix} errors:\n" +
            missing.map { "- #{message_for(_1)}" }.join("\n")
        end
      end

      def message_for(leaf)
        path = 'root'

        leaf.path&.reverse_each do |key|
          path = Errors::Nested.key_to_s(key, path)
        end

        "#{path}: #{leaf.message}"
      end
    end
  end
end
