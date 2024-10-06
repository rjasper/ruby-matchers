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

    def ~
      ImplyOneMatcher.new(@matchers, else: @else)
    end

    def check(_actual)
      matchers = @neg_matchers.filter { yield(_1.condition).valid? }

      if matchers.empty?
        errors << yield(@neg_else) if @else
      elsif matchers.length == 1
        errors << yield(matchers[0])
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
