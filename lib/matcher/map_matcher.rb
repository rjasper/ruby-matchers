# frozen_string_literal: true

module Matcher
  class MapMatcher < Base
    def initialize(projection, matcher)
      super()

      @projection = projection
      @matcher = matcher
    end

    def check(actual)
      unless actual.respond_to?(:map)
        errors << "expected to respond to \"map\" but got #{actual.inspect}"
        return
      end

      mapped = []
      mapping_failed = false

      actual.map.with_index do |item, i|
        mapped << @projection.evaluate(item)
      rescue Expression::NotRespondingError => e
        errors[i] << e.message_for_errors
        mapping_failed = true
      end

      errors << @matcher.match(mapped) unless mapping_failed
    end

    def inspect
      "map(#{@projection.inspect}, #{@matcher.inspect})"
    end
  end
end
