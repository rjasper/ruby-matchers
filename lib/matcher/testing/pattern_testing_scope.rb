# frozen_string_literal: true

module Matcher
  class PatternTestingScope
    include PatternBuilding

    def initialize(pattern, test)
      @pattern = pattern
      @test = test
    end

    def assert_pattern_match(test_expression, **expected)
      expected = expected.transform_values do |v|
        Matcher::ExpressionRecorder.transform(v)
      end

      test_expression = Matcher::ExpressionRecorder.transform(test_expression)

      result = @pattern.match(test_expression)

      flunk "#{test_expression} did not match #{@pattern}" unless result

      expected.each_pair do |key, value|
        @test.assert_equal value, result[key]&.expression, "for #{key.inspect}"
      end
    end

    def assert_no_pattern_match(test_expression)
      test_expression = Matcher::ExpressionRecorder.transform(test_expression)

      @test.assert_nil(@pattern.match(test_expression))
    end
  end
end
