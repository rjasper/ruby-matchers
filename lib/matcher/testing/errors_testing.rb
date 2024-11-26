# frozen_string_literal: true

module Matcher
  module ErrorsTesting
    def empty
      EmptyError.instance
    end

    def element(message)
      ElementError.new(message)
    end

    def nested(key, error)
      NestedError.new(key, error)
    end

    def nested_from(key, error)
      NestedError.from(key, error)
    end

    def _and(*errors)
      AndError.new(errors)
    end

    def _or(*errors)
      OrError.new(errors)
    end

    def msg(actual)
      StandardMessageBuilder.new(false, actual)
    end

    def assert_phrase(expected, message)
      assert_equal expected, Matcher::ExpectedPhrasing.new(nil, message).apply
    end
  end
end
