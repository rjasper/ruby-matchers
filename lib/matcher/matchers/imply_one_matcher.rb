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

    def ~
      NegatedImplyOneMatcher.new(@matchers, else: @else)
    end

    def check(actual)
      matchers = @matchers.filter { yield(_1.condition).valid? }

      if matchers.empty?
        errors << if @else
          yield @else
        else
          report.namespace(:imply_one).no_condition_satisfied(@matchers.map(&:condition))
        end

        return
      elsif matchers.length > 1
        errors << report.namespace(:imply_one).multiple_conditions_satisfied(matchers.map(&:condition))
      end

      matchers.each { errors << yield(_1.matcher) }
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
