# frozen_string_literal: true

module Matcher
  module Assertions
    def assert_structure(actual, &)
      errors = Matcher.build(&).match(actual)

      # rubocop:disable Minitest/AssertWithExpectedArgument
      assert(false, <<~TEXT.chomp) unless errors.empty?
        For object:

        #{actual.inspect}

        The following conditions were not satisfied:

        #{errors.message}
      TEXT
      # rubocop:enable Minitest/AssertWithExpectedArgument
    end
  end
end
