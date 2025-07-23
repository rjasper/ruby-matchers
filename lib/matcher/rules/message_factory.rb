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

    def create(context, value_tree)
      # Using reduce instead of dig so it will fail if an unexpected leaf is encountered.
      values = @value_paths.transform_values { _1.reduce(value_tree, :[]) }
      message = context.instance_exec(values, @expressions, &@block)
      message.negate! if @negate

      message
    end
  end
end
