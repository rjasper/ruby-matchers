# frozen_string_literal: true

module Matcher
  class MessageFactory
    def initialize(value_paths, expressions, block)
      @value_paths = value_paths
      @expressions = expressions
      @negate = false
      @block = block
    end

    def negate!
      @negate = !@negate
    end

    def create(matcher, value_tree)
      values = @value_paths.transform_values { _1.reduce(value_tree, :[]) }
      message = matcher.instance_exec(values, @expressions, &@block)
      message.negate! if @negate

      message
    end
  end
end
