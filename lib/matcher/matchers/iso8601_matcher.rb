# frozen_string_literal: true

require 'time'

module Matcher
  class Iso8601Matcher < Base
    def initialize(time = nil, negated: false)
      super()

      @time =
        if time.is_a?(String)
          Time.parse(time)
        elsif time.nil? || time.instance_of?(Time)
          time
        else
          time.to_time
        end

      @negated = negated
    end

    def ~
      Iso8601Matcher.new(@time, negated: !@negated)
    end

    def check(actual)
      unless actual.is_a?(String)
        errors << expected.kind_of(String) unless @negated
        return
      end

      time = Time.iso8601(actual)

      if @time
        errors << expected.not_if(@negated).equal(@time) if @negated ^ (time != @time)
      elsif @negated
        errors << expected.namespace(:iso8601).not.valid
      end
    rescue ArgumentError
      errors << expected.namespace(:iso8601).valid unless @negated
    end
    protected :check

    def to_s
      "#{'~' if @negated}iso8601#{"(#{@time.iso8601.inspect})" if @time}"
    end
  end

  module MatcherBuilding
    def iso8601(string_or_time = nil)
      Iso8601Matcher.new(string_or_time)
    end
  end
end
