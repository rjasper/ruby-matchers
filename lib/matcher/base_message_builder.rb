# frozen_string_literal: true

module Matcher
  class BaseMessageBuilder
    def initialize(negated, actual)
      @negated = negated
      @actual = actual
    end

    def not_if(condition)
      condition ? self.not : self
    end

    protected

    def message(key, *, **)
      Message.new(key, @negated, @actual, *, **)
    end

    private

    def method_missing(method, *, **)
      message(method, *, **)
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end
  end
end
