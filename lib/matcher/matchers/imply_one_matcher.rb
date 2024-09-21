# frozen_string_literal: true

module Matcher
  class ImplyOneMatcher < Base
    def self.check_matchers(matchers)
      invalid_matcher = matchers.find { !_1.is_a?(ImplyMatcher) }

      raise "Not an ImplyMatcher: #{invalid_matcher.inspect}" if invalid_matcher
    end

    def initialize(matchers)
      ImplyOneMatcher.check_matchers(matchers)

      super()

      @matchers = matchers
    end

    def negated
      NegatedImplyOneMatcher.new(@matchers)
    end

    def check(**)
      matchers = @matchers.filter { _1.condition.match(**).valid? }

      if matchers.empty?
        errors << "expected #{get_actual(**).inspect} to satisfy one of these conditions: #{list_conditions_of(@matchers)}"
      elsif matchers.length > 1
        errors << "expected #{get_actual(**).inspect} to satisfy only one condition, but met these: #{list_conditions_of(matchers)}"
      end

      matchers.each { errors << _1.matcher.match(**) }
    end
    protected :check

    def to_s
      "imply_one(#{@matchers.map(&:to_s).join(', ')})"
    end

    private

    def list_conditions_of(matchers)
      matchers.map { _1.condition.to_s }.join(', ')
    end
  end
end
