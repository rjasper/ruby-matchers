# frozen_string_literal: true

module Matcher
  class MapMatcher < Base
    def initialize(projection, matcher, index: :index, original: :original)
      super()

      @projection = projection
      @matcher = matcher
      @index = index
      @original = original
    end

    def check(actual, **values)
      unless actual.respond_to?(:map)
        errors << "expected to respond to \"map\" but got #{actual.inspect}"
        return
      end

      mapped = []
      mapping_failed = false

      actual.map.with_index do |item, i|
        mapped << @projection.evaluate({
          **values,
          actual: item,
          @index => i,
          @original => actual,
        })
      rescue Call::NotRespondingError => e
        errors[i] << e.message_for_errors
        mapping_failed = true
      end

      return if mapping_failed

      mapped_errors = @matcher.match(mapped, **values, @original => actual)

      unless mapped_errors.base.empty?
        base_projection = Call.build { _1.map_expression(@projection) }
        mapped_errors.base.each { errors[base_projection] << _1 }
      end

      mapped_errors.attributes.each { errors[_1][@projection] << _2 }
    end

    def inspect
      "map(#{@projection.inspect}, #{@matcher.inspect})"
    end
  end
end
