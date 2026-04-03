# frozen_string_literal: true

module Matcher
  class ErrorCollector
    def self.error_from(obj)
      case obj
      when String, Message
        ElementError.new(obj)
      when Error
        obj
      else
        "Unexpected error object: #{obj.inspect}"
      end
    end

    attr_reader :error

    def initialize
      @error = EmptyError.instance
      @mode = :and
    end

    def empty?
      @error.valid?
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

    class Brackets
      def initialize(parent, key)
        @parent = parent
        @key = key
      end

      def error
        @parent.error
      end

      def <<(error)
        error = ErrorCollector.error_from(error)

        return error if error.is_a?(EmptyError) || @key == Variable.actual

        key = if @key.is_a?(Expression)
          @key
        else
          Call.new(Variable.actual, :[], [Constant.new(@key)])
        end

        @parent << NestedError.new(key, error)

        @parent.error
      end

      def [](key)
        Brackets.new(self, key)
      end
    end

    def <<(error)
      return @error if error.is_a?(EmptyError)

      error = ErrorCollector.error_from(error)

      case @error
      when EmptyError
        @error = error
      when and? ? AndError : OrError
        @error << error
      else
        if and?
          @error &= error
        else
          @error |= error
        end
      end

      @error
    end

    def [](key)
      Brackets.new(self, key)
    end

    def clear
      @error = EmptyError.instance
    end
  end
end
