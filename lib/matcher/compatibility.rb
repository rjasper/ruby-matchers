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
  end
end
