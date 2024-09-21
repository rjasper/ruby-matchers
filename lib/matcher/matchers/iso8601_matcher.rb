# frozen_string_literal: true

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

    def negated
      Iso8601Matcher.new(@time, negated: !@negated)
    end

    def check(actual:, **)
      unless actual.is_a?(String)
        errors << "expected a String but got #{actual.inspect}" unless @negated
        return
      end

      time = Time.iso8601(actual)

      if @negated
        if @time
          errors << "did not expect an ISO 8601 string for #{time} but got #{actual.inspect}" if @time == time
        else
          errors << "did not expect an ISO 8601 string but got #{actual.inspect}"
        end
      else
        errors << "expected #{@time} but got #{time}" if @time&.!= time
      end
    rescue ArgumentError
      errors << "expected an ISO 8601 string but got #{actual.inspect}" unless @negated
    end
    protected :check

    def to_s
      "#{'~' if @negated}iso8601#{"(#{@time.iso8601.inspect})" if @time}"
    end
  end
end
