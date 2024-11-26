# frozen_string_literal: true

module Matcher
  module ErrorsHelpers
    def empty
      EmptyError.instance
    end

    def element(message)
      ElementError.new(message)
    end

    def nested(key, node)
      NestedError.new(key, node)
    end

    def nested_from(key, node)
      NestedError.from(key, node)
    end

    def _and(*nodes)
      AndError.new(nodes)
    end

    def _or(*nodes)
      OrError.new(nodes)
    end

    def msg(actual)
      StandardMessageBuilder.new(false, actual)
    end

    def assert_phrase(expected, message)
      assert_equal expected, Matcher::ExpectedPhrasing.new(nil, message).apply
    end
  end
end
