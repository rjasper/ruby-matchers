# frozen_string_literal: true

module Matcher
  class XmlMatcherBuilder
    def initialize
      @stack = []
      @nodes = []
      @others = nil
    end

    def parse

    end

    def node(tag, attributes)
      node_matcher = if block_given?
        @stack.push([@nodes, @others])
        @nodes = []
        @others = nil

        begin
          yield

          children = @nodes
          others = @others
        ensure
          @nodes, @others = @stack.pop
        end

        XmlNodeMatcher.new(tag, attributes, children, others)
      else
        XmlNodeMatcher.new(tag, attributes)
      end

      @nodes << node_matcher

      node_matcher
    end

    def others(matcher = UNDEFINED)
      raise "others already called with: #{@others}" if @others

      return Pipe.new { others(_1) } if Matcher.undefined?(matcher)

      @others = Matcher.of(matcher)
    end

    def search(css)

    end

    def children(matcher = UNDEFINED)

    end

    # def css(pattern)
    #
    # end
  end

  module MatcherBuilding
    def xml
      @xml ||= XmlMatcherBuilder.new
    end
  end
end
