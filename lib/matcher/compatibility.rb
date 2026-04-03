# frozen_string_literal: true

module Matcher
  module Compatibility
    extend self

    # rubocop:disable Style/ClassVars

    @@method_quote_delimiter = caller[0].include?("`") ? "`" : "'"

    # rubocop:enable Style/ClassVars

    def quote_method(method)
      "#{@@method_quote_delimiter}#{method}'"
    end

    def nil_kwargs?
      test_nil_kwargs(**nil)
    rescue TypeError
      false
    end

    # rubocop:disable Naming/PredicateMethod

    def test_nil_kwargs(**)
      true
    end
    private :test_nil_kwargs

    # rubocop:enable Naming/PredicateMethod

    NULL_KWARGS = nil_kwargs? ? nil : {}.freeze
  end
end
