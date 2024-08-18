# frozen_string_literal: true

module Matcher
  class Iso8601Matcher < Base
    def initialize(time = nil)
      super()

      @time =
        if time.is_a?(String)
          Time.parse(time)
        elsif time.nil? || time.instance_of?(Time)
          time
        else
          time.to_time
        end
    end

    def check(actual, **)
      unless actual.is_a?(String)
        errors << "expected a String but got #{actual.inspect}"
        return
      end

      time = Time.iso8601(actual)

      errors << "expected #{@time} but got #{time}" if @time&.!= time
    rescue ArgumentError
      errors << "expected an ISO 8601 string but got #{actual.inspect}"
    end
    protected :check

    def inspect
      "iso8601#{"(#{@time.iso8601.inspect})" if @time}"
    end
  end
end
