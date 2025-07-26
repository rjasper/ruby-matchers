# frozen_string_literal: true

module Matcher
  class Undefined
    include Singleton
    include NoMatcher
    include NoExpression
  end
end
