# frozen_string_literal: true

module Matcher
  class ErrorCollector
    def self.error_from(obj)
      case obj
      when String, ErrorMessage
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

    def or!
      @mode = :or
      self
    end

    def and!
      @mode = :and
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

      def <<(error)
        error = ErrorCollector.error_from(error)

        @parent << NestedError.from(@key, error)
      end

      def [](key)
        Brackets.new(self, key)
      end
    end

    def <<(error)
      return if error.is_a?(EmptyError)

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
    end

    def [](key)
      Brackets.new(self, key)
    end

    def clear
      @error = EmptyError.instance
    end
  end
end
