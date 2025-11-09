# frozen_string_literal: true

module Matcher
  class StandardMessageBuilder < MessageBuilder
    def namespace(namespace)
      NamespacedMessageBuilder.new(@negated, @actual, namespace)
    end

    def truthy
      message(:truthy)
    end

    def same(object)
      message(:same, object)
    end

    def equal(value)
      message(:equal, value)
    end

    def less_than(operand)
      message(:less_than, operand)
    end

    def greater_than(operand)
      message(:greater_than, operand)
    end

    def less_than_or_equal(operand)
      message(:less_than_or_equal, operand)
    end

    def greater_than_or_equal(operand)
      message(:greater_than_or_equal, operand)
    end

    def comparable_to(operand)
      message(:comparable_to, operand)
    end

    def between(min, max, exclude_end: false)
      message(:between, min, max, exclude_end:)
    end

    def length_of(exp, act)
      message(:length_of, exp, act)
    end

    def having_key(key)
      message(:having_key, key)
    end

    def having_index(index)
      message(:having_index, index)
    end

    def exist
      message(:exist)
    end

    def in(collection)
      message(:in, collection)
    end

    def including(item)
      message(:including, item)
    end

    def duplicate(original_index)
      message(:duplicate, original_index)
    end

    def duplicate_by(expression, value, original_index)
      message(:duplicate_by, expression, value, original_index)
    end

    def matching(pattern)
      message(:matching, pattern)
    end

    def valid_format(format)
      message(:valid_format, format)
    end

    def instance_of(klass)
      message(:instance_of, klass)
    end

    def kind_of(klass)
      message(:kind_of, klass)
    end

    def responding_to(method)
      message(:responding_to, method)
    end

    def predicate(name)
      message(:predicate, name)
    end

    def described_by(description)
      message(:described_by, description)
    end
  end
end
