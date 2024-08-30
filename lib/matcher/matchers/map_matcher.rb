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

    def check(actual:, **values)
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

      mapped_errors = @matcher.match(**values, actual: mapped, @original => actual)

      errors << map_errors(mapped_errors)
    end
    protected :check

    def inspect
      "map(#{@projection.inspect}, #{@matcher.inspect})"
    end

    private

    def map_errors(node)
      case node
      when Errors::Empty
        node
      when Errors::And, Errors::Or
        node.class.new(node.nodes)
      when Errors::Nested
        if node.key.is_a?(Integer)
          nested_projection = Errors::Nested.from(@projection, node.node)
          Errors::Nested.from(node.key, nested_projection)
        else
          node
        end
      when Errors::Element
        base_projection = Call.build { _1.map_expression(@projection) }
        Errors::Nested.from(base_projection, node)
      else
        raise "Unexpected node: #{node.inspect}"
      end
    end
  end
end
