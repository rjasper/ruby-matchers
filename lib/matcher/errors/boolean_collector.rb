# frozen_string_literal: true

module Matcher
  class BooleanCollector
    def initialize
      @result = true
      @mode = :and
    end

    def or!
      @mode = :or
      self
    end

    def or?
      @mode == :or
    end

    def and?
      @mode == :and
    end

    def empty?
      @result
    end

    INVALID_ERROR = ElementError.new('invalid')
    private_constant :INVALID_ERROR

    def error
      @result ? EmptyError.instance : INVALID_ERROR
    end

    def <<(error)
      if !error.is_a?(Error) || !error.valid?
        @result = false
        throw :mismatch if and?
      end

      self.error
    end

    def [](_key)
      self
    end

    def clear
      @result = true
    end
  end
end
