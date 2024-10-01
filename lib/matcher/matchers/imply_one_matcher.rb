# frozen_string_literal: true

module Matcher
  class ImplyOneMatcher < Base
    def self.check_matchers(matchers)
      invalid_matcher = matchers.find { !_1.is_a?(ImplyMatcher) }

      raise "Not an ImplyMatcher: #{invalid_matcher.inspect}" if invalid_matcher
    end

    def initialize(matchers, else: nil)
      ImplyOneMatcher.check_matchers(matchers)

      super()

      @matchers = matchers
      @else = { else: }[:else]
    end

    def negated
      NegatedImplyOneMatcher.new(@matchers, else: @else)
    end

    def check(**)
      matchers = @matchers.filter { _1.condition.match(**).valid? }

      if matchers.empty?
        errors << if @else
          @else.match(**)
        else
          "expected #{get_actual(**).inspect} to satisfy one of these conditions: #{list_conditions_of(@matchers)}"
        end

        return
      elsif matchers.length > 1
        errors << "expected #{get_actual(**).inspect} to satisfy only one condition, but met these: #{list_conditions_of(matchers)}"
      end

      matchers.each { errors << _1.matcher.match(**) }
    end
    protected :check

    def to_s
      matchers = @matchers.map(&:to_s).join(', ')

      if @else
        "imply_one(#{matchers}, else: #{@else})"
      else
        "imply_one(#{matchers})"
      end
    end

    private

    def list_conditions_of(matchers)
      matchers.map { _1.condition.to_s }.join(', ')
    end
  end
end
