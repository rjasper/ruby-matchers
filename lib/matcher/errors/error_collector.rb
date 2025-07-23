# frozen_string_literal: true

module Matcher
  class ErrorCollector
    def self.error_from(obj, values)
      case obj
      when String
        ElementError.new(obj)
      when Message
        obj = obj.bind(values[:actual]) unless obj.bound?

        ElementError.new(obj)
      when Error
        obj
      else
        "Unexpected error object: #{obj.inspect}"
      end
    end

    attr_reader :error

    def initialize(values)
      @error = EmptyError.instance
      @mode = :and
      @values = values
    end

    def empty?
      @error.valid?
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
      def initialize(parent, key, values)
        @parent = parent
        @key = key
        @values = values
      end

      def error
        @parent.error
      end

      def <<(error)
        error = ErrorCollector.error_from(error, @values)

        return error if error.is_a?(EmptyError) || @key == Variable.actual

        key = @key
        key = Call.new(Variable.actual, :[], [Constant.new(key)]) unless key.is_a?(Expression)
        key = key.bind(@values) if @values

        @parent << NestedError.new(key, error)

        @parent.error
      end

      def [](key)
        Brackets.new(self, key, @values)
      end
    end

    def <<(error)
      return @error if error.is_a?(EmptyError)

      error = ErrorCollector.error_from(error, @values)

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
      Brackets.new(self, key, @values)
    end

    def clear
      @error = EmptyError.instance
    end
  end
end
