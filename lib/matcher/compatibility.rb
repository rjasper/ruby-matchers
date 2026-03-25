# frozen_string_literal: true

module Matcher
  module Compatibility
    extend self

    @@method_quote_delimiter = caller[0].include?('`') ? '`' : "'"

    def quote_method(method)
      "#{@@method_quote_delimiter}#{method}'"
    end
  end
end
