# frozen_string_literal: true

module Matcher
  module ErrorsHelpers
    def empty
      Errors::Empty.instance
    end

    def element(message)
      Errors::Element.new(message)
    end

    def nested(key, node)
      Errors::Nested.from(key, node)
    end

    def _and(*nodes)
      Errors::And.new(nodes)
    end

    def _or(*nodes)
      Errors::Or.new(nodes)
    end
  end
end
