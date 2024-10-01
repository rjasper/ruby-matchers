# frozen_string_literal: true

module Matcher
  class NegatedImplyOneMatcher < Base
    def initialize(matchers, else: nil)
      ImplyOneMatcher.check_matchers(matchers)

      super()

      @matchers = matchers
      @neg_matchers = matchers.map(&:~)
      @else = { else: }[:else]
      @neg_else = @else&.~
    end

    def negated
      ImplyOneMatcher.new(@matchers, else: @else)
    end

    def check(**)
      matchers = @neg_matchers.filter { _1.condition.match(**).valid? }

      if matchers.empty?
        errors << @neg_else.match(**) if @else
      elsif matchers.length == 1
        errors << matchers[0].match(**)
      end
    end
    protected :check

    def to_s
      matchers = @matchers.map(&:to_s).join(', ')

      if @else
        "~imply_one(#{matchers}, else: #{@else})"
      else
        "~imply_one(#{matchers})"
      end
    end
  end
end
