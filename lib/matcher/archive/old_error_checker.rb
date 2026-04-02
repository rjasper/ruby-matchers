# frozen_string_literal: true

module Matcher
  class OldErrorChecker
    def self.check(expected, actual, phrasing: nil)
      new(phrasing).check(expected, actual)
    end

    def initialize(phrasing = nil)
      @phrasing = phrasing
    end

    def check(expected, actual)
      labeler = ErrorLabeler.new(@phrasing)
      expected_label, expected_leaves = labeler.label_tree(expected)
      actual_label, actual_leaves = labeler.label_tree(actual)

      return if expected_label == actual_label

      missing_messages = [
        missing_message("missing", expected_leaves - actual_leaves),
        missing_message("extra", actual_leaves - expected_leaves),
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
      path = "root"

      leaf.path&.reverse_each do |key|
        path = NestedError.key_to_s(key, path)
      end

      "#{path}: #{leaf.message}"
    end
  end
end
