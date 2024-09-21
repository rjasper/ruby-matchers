# frozen_string_literal: true

module Matcher
  class NegatedImplyOneMatcher < Base
    def initialize(matchers)
      ImplyOneMatcher.check_matchers(matchers)

      super()

      @matchers = matchers
      @neg_matchers = matchers.map(&:~)
    end

    def negated
      ImplyOneMatcher.new(@matchers)
    end

    def check(**)
      matchers = @neg_matchers.filter { _1.condition.match(**).valid? }

      return if matchers.length != 1

      errors << matchers[0].match(**)
    end
    protected :check

    def to_s
      "~imply_one(#{@matchers.map(&:to_s).join(', ')})"
    end
  end
end
