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

    attr_reader :node

    def initialize
      @node = EmptyError.instance
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

      def <<(node)
        node = ErrorCollector.error_from(node)

        @parent << NestedError.from(@key, node)
      end

      def [](key)
        Brackets.new(self, key)
      end
    end

    def <<(node)
      return if node.is_a?(EmptyError)

      node = ErrorCollector.error_from(node)

      case @node
      when EmptyError
        @node = node
      when and? ? AndError : OrError
        @node << node
      else
        if and?
          @node &= node
        else
          @node |= node
        end
      end
    end

    def [](key)
      Brackets.new(self, key)
    end

    def clear
      @node = EmptyError.instance
    end
  end
end
