# frozen_string_literal: true

module Matcher
  class AstMapping
    def initialize(path = List.empty)
      @path = path
    end

    attr_reader :path

    def receiver
      @receiver ||= AstMapping.new(@path << :receiver)
    end

    def args
      @args ||= Args.new(@path << :args, [])
    end

    def kwargs
      @kwargs ||= Args.new(@path << :kwargs, {})
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
