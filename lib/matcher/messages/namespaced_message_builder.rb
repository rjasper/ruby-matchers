# frozen_string_literal: true

module Matcher
  class NamespacedMessageBuilder < MessageBuilder
    def initialize(negated, actual, namespace)
      super(negated, actual)

      @namespace = namespace
    end

    def not
      NamespacedMessageBuilder.new(!@negated, @actual, @namespace)
    end

    protected

    def message(key, *, **)
      key = [@namespace, key]

      super
    end
  end
end
