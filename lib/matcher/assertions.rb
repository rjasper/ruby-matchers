# frozen_string_literal: true

module Matcher
  module Assertions
    def assert_structure(actual, &)
      errors = Matcher.build(&).match(actual)

      assert(false, <<~TEXT.chomp) unless errors.valid?
        For object:

        #{actual.inspect}

        The following conditions were not satisfied:

        #{Reporter.report(errors)}
      TEXT
    end
  end
end
