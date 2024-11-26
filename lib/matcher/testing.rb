# frozen_string_literal: true

module Matcher
  module Testing
    def expression(&)
      Expression.build(&)
    end

    def build_errors(&)
      Testing::ErrorBuilder.build(&)
    end

    def assert_errors(actual, *base, **nested, &block)
      assert_errors_helper(actual, base, nested, block, phrasing: ExpectedPhrasing.phrasing)
    end

    def assert_no_errors(actual)
      assert(false, <<~TEXT.chomp) unless actual.valid?
        The following conditions were not satisfied:

        #{Reporter.report(actual)}
      TEXT
    end

    private

    def assert_errors_helper(actual, base, nested, block, phrasing: nil)
      raise 'cannot pass expected errors directly if block given' if
        (!base.empty? || !nested.empty?) && block

      expected_nodes = if block
        Testing::ErrorBuilder.build_nodes(&block)
      else
        base.map { ElementError.new(_1) } + nested_from_hash(nested)
      end

      expected = AndError.from(expected_nodes)
      message = Testing::ErrorsChecker.check(expected, actual, phrasing:)

      return unless message

      assert false, message
    end

    def nested_from_hash(hash)
      hash.map do |key, value|
        node = if value.is_a?(Hash)
          AndError.from(nested_from_hash(value))
        else
          ElementError.new(value)
        end

        NestedError.from(key, node)
      end
    end
  end
end
