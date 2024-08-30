# frozen_string_literal: true

module Matcher
  module Testing
    def match(actual, &)
      Matcher.build(&).match(actual)
    end

    def v(value)
      EqualMatcher.new(value)
    end

    def a(array)
      ArrayMatcher.new(array)
    end

    def h(**hash)
      HashMatcher.new(hash)
    end

    def expr(&)
      Call.build(&)
    end

    def empty
      Errors::Empty.instance
    end

    def element(message)
      Errors::Element.new(message)
    end

    def nested(key, node)
      Errors::Nested.new(key, node)
    end

    def _and(*nodes)
      Errors::And.new(nodes)
    end

    def _or(*nodes)
      Errors::Or.new(nodes)
    end

    def assert_errors(actual, *base, **nested, &block)
      raise 'cannot pass expected errors directly if block given' if
        (!base.empty? || !nested.empty?) && block

      expected_nodes = if block
        Testing::ErrorBuilder.build_nodes(&block)
      else
        base.map { Errors::Element.new(_1) } +
          nested_from_hash(nested)
      end

      expected = Errors::And.from(expected_nodes)

      message = Testing::ErrorsChecker.check(expected, actual)

      return unless message

      assert false, message
    end

    def assert_no_errors(actual)
      assert(false, <<~TEXT.chomp) unless actual.valid?
        The following conditions were not satisfied:

        #{Reporter.report(actual)}
      TEXT
    end

    private

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
