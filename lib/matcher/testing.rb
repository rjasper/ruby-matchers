# frozen_string_literal: true

module Matcher
  module Testing
    def expression(&)
      Expression.build(&)
    end

    def build_errors(&)
      ErrorBuilder.build(&)
    end

    def assert_errors(actual, *base, **nested, &block)
      assert_errors_helper(actual, base, nested, block)
    end

    def assert_or_errors(actual, *base, **nested, &block)
      assert_errors_helper(actual, base, nested, block, use_or: true)
    end

    def assert_no_errors(actual)
      assert(false, <<~TEXT.chomp) unless actual.valid?
        The following conditions were not satisfied:

        #{Reporter.report(actual)}
      TEXT
    end

    def msg(actual)
      StandardMessageBuilder.new(false, actual)
    end

    private

    def assert_errors_helper(
      actual, base, nested, block,
      phrasing: ExpectedPhrasing.phrasing, use_or: false
    )
      raise "cannot pass expected errors directly if block given" if
        (!base.empty? || !nested.empty?) && block

      expected_nodes = if block
        ErrorBuilder.build_errors(&block)
      else
        base.map { ElementError.new(_1) } + nested_from_hash(nested, use_or:)
      end

      error_klass = use_or ? OrError : AndError
      expected = error_klass.from(expected_nodes)

      assert false, "expected an error but no error present" if
        expected.valid? && actual.valid?

      checker = ErrorChecker.new(phrasing)
      result = checker.check(expected, actual)

      return if result.ok

      reporter = Reporter.new

      io = StringIO.new

      io.puts <<~TEXT
        #{result.reason}

        expected:

        #{reporter.report(expected).chomp}

        but got:

        #{reporter.report(actual).chomp}
      TEXT

      missing_phrases = result.missing_phrases
      if missing_phrases && !missing_phrases.empty?
        io.puts "\nmissing:"
        missing_phrases.each do |phrase, count|
          io.puts "- #{phrase}#{"(#{count}x)" if count > 1}"
        end
      end

      extra_phrases = result.extra_phrases
      if extra_phrases && !extra_phrases.empty?
        io.puts "\nextra:"
        extra_phrases.each do |phrase, count|
          io.puts "- #{phrase}#{"(#{count}x)" if count > 1}"
        end
      end

      assert false, io.string
    end

    def nested_from_hash(hash, use_or: false)
      hash.map do |key, value|
        node = if value.is_a?(Hash)
          klass = use_or ? OrError : AndError
          klass.from(nested_from_hash(value, use_or:))
        else
          ElementError.new(value)
        end

        NestedError.from(key, node)
      end
    end
  end
end
