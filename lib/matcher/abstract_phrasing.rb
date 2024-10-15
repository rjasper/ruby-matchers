# frozen_string_literal: true

require 'forwardable'

module Matcher
  class AbstractPhrasing
    extend Forwardable

    attr_reader :path, :message
    def_delegator :@message, :actual
    def_delegator :@message, :negated

    def self.namespace(value)
      @namespace = value
      yield
    ensure
      @namespace = nil
    end

    def self.define(key, &block)
      key = [@namespace, key] if @namespace

      dict[key] = block
    end

    def self.dict
      @dict ||= {}
    end

    def self.phrasing
      ->(path, message) { new(path, message).apply }
    end

    def initialize(path, message)
      @path = path
      @message = message
    end

    def apply
      block = self.class.dict[@message.key]
      instance_exec(*@message.args, **@message.kwargs, &block)
    end
  end
end
