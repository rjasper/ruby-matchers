# frozen_string_literal: true

module Matcher
  class AstMapping
    RECEIVER = 0
    ARGS = 1
    KWARGS = 2

    def initialize(path = List.empty)
      @path = path
    end

    attr_reader :path

    def receiver
      @receiver ||= AstMapping.new(@path << RECEIVER)
    end

    def args
      @args ||= Args.new(@path << ARGS, [])
    end

    def kwargs
      @kwargs ||= Args.new(@path << KWARGS, {})
    end

    class Args
      extend Forwardable

      def initialize(path, data)
        @path = path
        @data = data
      end

      attr_reader :path, :data

      def [](index)
        @data[index] ||= AstMapping.new(@path << index)
      end
    end
  end
end
