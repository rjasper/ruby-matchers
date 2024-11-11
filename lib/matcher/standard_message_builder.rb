# frozen_string_literal: true

module Matcher
  class StandardMessageBuilder < BaseMessageBuilder
    def namespace(namespace)
      NamespacedMessageBuilder.new(@negated, @actual, namespace)
    end

    def not
      StandardMessageBuilder.new(!@negated, @actual)
    end

    def not_if(condition)
      condition ? self.not : self
    end

    def between(min, max, exclude_end = false)
      message(:between, min, max, exclude_end)
    end

    def equal(value)
      message(:equal, value)
    end

    def lower_than(operand)
      message(:lower_than, operand)
    end

    def greater_than(operand)
      message(:greater_than, operand)
    end

    def lower_or_equal_than(operand)
      message(:lower_or_equal_than, operand)
    end

    def greater_or_equal_than(operand)
      message(:greater_or_equal_than, operand)
    end

    def comparable_to(operand)
      message(:comparable_to, operand)
    end

    def described_by(description)
      message(:described_by, description)
    end

    def having_key(key)
      message(:having_key, key)
    end

    def kind_of(klass)
      message(:kind_of, klass)
    end

    def length_of(length)
      message(:length_of, length)
    end

    def matching(pattern)
      message(:matching, pattern)
    end

    def member_of(collection)
      message(:member_of, collection)
    end

    def responding_to(method)
      message(:responding_to, method)
    end

    def included_in(operand)
      message(:included_in, operand)
    end

    def predicate(name)
      message(:predicate, name)
    end
  end
end
