# frozen_string_literal: true

module Matcher
  class MapMatcher < Base
    def self.map_errors(node, projection)
      case node
      when Errors::Empty
        node
      when Errors::And, Errors::Or
        children = node.nodes.map { map_errors(_1, projection) }
        node.class.new(children)
      when Errors::Nested
        if node.key.is_a?(Integer)
          nested_projection = Errors::Nested.from(projection, node.node)
          Errors::Nested.from(node.key, nested_projection)
        else
          node
        end
      when Errors::Element
        base_projection = Call.build { _1.map_expression(projection) }
        Errors::Nested.from(base_projection, node)
      else
        raise "Unexpected node: #{node.inspect}"
      end
    end

    def initialize(projection, matcher, index: :index, original: :original)
      super()

      @projection = projection
      @matcher = matcher
      @index = index
      @original = original
    end

    def negated
      NegatedMapMatcher.new(@projection, @matcher, index: @index, original: @original)
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
      rescue Call::Error => e
        errors[i] << e.message_for_errors
        mapping_failed = true
      end

      return if mapping_failed

      mapped_errors = @matcher.match(**values, actual: mapped, @original => actual)

      errors << MapMatcher.map_errors(mapped_errors, @projection)
    end
    protected :check

    def to_s
      "map(#{@projection}, #{@matcher})"
    end
  end
end
