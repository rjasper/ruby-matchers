# frozen_string_literal: true

module Matcher
  PatternCapture = Struct.new(:expression, :mapping) do
    def value_path
      identifiers = mapping.path.to_a.reverse!
      identifiers << -1
      identifiers
    end
  end
end
