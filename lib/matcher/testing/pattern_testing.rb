# frozen_string_literal: true

module Matcher
  module PatternTesting
    def with_pattern(pattern, &)
      pattern = Pattern.build(&pattern)

      PatternTestingScope.new(pattern, self).instance_exec(&)
    end
  end
end
