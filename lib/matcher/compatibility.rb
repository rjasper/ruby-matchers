# frozen_string_literal: true

module Matcher
  module Compatibility
    extend OnceBefore
    extend self

    def quote_method(method)
      "#{@@method_quote_delimiter}#{method}'"
    end

    once_before :quote_method do
      @@method_quote_delimiter = caller[0].include?('`') ? '`' : "'"
    end
  end
end
