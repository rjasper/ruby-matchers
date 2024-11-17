# frozen_string_literal: true

module Matcher
  module Testing
    def expression(&)
      Expression.build(&)
    end

    def empty
      Errors::Empty.instance
    end

    def element(message)
      Errors::Element.new(message)
    end

    def nested(key, node)
      Errors::Nested.from(key, node)
    end

    def _and(*nodes)
      Errors::And.new(nodes)
    end

    def _or(*nodes)
      Errors::Or.new(nodes)
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
        base.map { Errors::Element.new(_1) } + nested_from_hash(nested)
      end

      expected = Errors::And.from(expected_nodes)
      message = Testing::ErrorsChecker.check(expected, actual, phrasing:)

      return unless message

      assert false, message
    end

    def nested_from_hash(hash)
      hash.map do |key, value|
        node = if value.is_a?(Hash)
          Errors::And.from(nested_from_hash(value))
        else
          Errors::Element.new(value)
        end

        Errors::Nested.from(key, node)
      end
    end
  end
end
