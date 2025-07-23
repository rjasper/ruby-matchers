# frozen_string_literal: true

module Matcher
  class ImplySomeMatcher < Base
    def self.check(matchers, else_matcher, count)
      raise "count must be a positive integer or :any. Got #{count.inspect}" if
        count != :any && (!count.is_a?(Integer) || count <= 0)

      raise 'else cannot be combined with count > 1' if
        else_matcher && count != :any && count != 1

      invalid_matcher = matchers.find { !_1.is_a?(ImplyMatcher) }

      raise "Not an ImplyMatcher: #{invalid_matcher.inspect}" if invalid_matcher
    end

    def self.else_matcher(else:)
      els = { else: }[:else]

      Matcher.null?(els) ? nil : Matcher.of(els)
    end

    def initialize(matchers, else_matcher, count)
      ImplySomeMatcher.check(matchers, else_matcher, count)

      super()

      @matchers = matchers
      @else_matcher = else_matcher
      @count = count
    end

    def ~
      NegatedImplySomeMatcher.new(@matchers, @else_matcher, @count)
    end

    def check(state)
      errors = state.errors
      matchers = @matchers.filter { yield(_1.condition).valid? }

      if matchers.empty?
        errors << if @else_matcher
          yield @else_matcher
        else
          report.namespace(:imply_some).no_condition_satisfied(@matchers.map(&:condition), @count)
        end

        return
      elsif @count != :any && matchers.length != @count
        errors << report.namespace(:imply_some).x_conditions_satisfied(matchers.map(&:condition), @count)
      end

      matchers.each { errors << yield(_1.matcher) }
    end

    def to_s
      args = @matchers.map(&:to_s)

      case @count
      when :any
        method = 'imply_any'
      when 1
        method = 'imply_one'
      else
        method = 'imply_some'
        args << "count: #{@count}"
      end

      args << "else: #{@else_matcher}" if @else_matcher

      "#{method}(#{args.join(', ')})"
    end
  end

  module MatcherBuilding
    def imply_one(*matchers, else: NULL)
      else_matcher = ImplySomeMatcher.else_matcher(else:)

      ImplySomeMatcher.new(matchers, else_matcher, 1)
    end

    def imply_any(*matchers, else: NULL)
      else_matcher = ImplySomeMatcher.else_matcher(else:)

      ImplySomeMatcher.new(matchers, else_matcher, :any)
    end

    def imply_some(*matchers, count:)
      ImplySomeMatcher.new(matchers, nil, count)
    end
  end
end
