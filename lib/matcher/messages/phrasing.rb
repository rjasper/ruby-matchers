# frozen_string_literal: true

module Matcher
  class Phrasing
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
      phrase(@message.key, *@message.args, **@message.kwargs)
    end

    def phrase(key, *, **)
      block = self.class.dict[key]

      if block
        instance_exec(*, **, &block)
      else
        "got #{actual.inspect} but found no message for #{key.inspect}#{" (negated)" if negated}"
      end
    end

    def phrase_negated(key, *, **)
      message = Message.new(key, !negated, actual, *, **)

      self.class.new(@path, message).apply
    end
  end
end
