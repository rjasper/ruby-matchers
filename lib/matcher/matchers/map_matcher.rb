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
        body = projection.to_s(substitutions: { actual: 'it' })
        key = Errors::Nested::Key.new(".map { |it| #{body} }")
        Errors::Nested.from(key, node)
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

    def ~
      NegatedMapMatcher.new(@projection, @matcher, index: @index, original: @original)
    end

    def check(actual)
      unless actual.respond_to?(:map)
        errors << "expected to respond to \"map\" but got #{actual.inspect}"
        return
      end

      mapped = []
      mapping_failed = false

      actual.map.with_index do |item, i|
        mapped << @projection.evaluate(
          values.merge(actual: item, @index => i, @original => actual),
        )
      rescue Call::Error => e
        errors[i] << e.message_for_errors
        mapping_failed = true
      end

      return if mapping_failed

      mapped_errors = yield @matcher, mapped, @original => actual

      errors << MapMatcher.map_errors(mapped_errors, @projection)
    end
    protected :check

    def to_s
      "map(#{@projection}, #{@matcher})"
    end
  end
end
