# frozen_string_literal: true

module Matcher
  class Reporter
    class << self
      delegate :report, to: :new
    end

    def initialize
      @level = 0
      @continue_line = false
      @path_stack = ['root']
    end

    def report(node)
      @io = StringIO.new

      report_node(node)

      string = @io.string
      @io.close
      @io = nil

      string
    end

    private

    def report_node(node)
      case node
      when Errors::Empty
        report_empty
      when Errors::Element
        report_element(node)
      when Errors::Nested
        report_nested(node)
      when Errors::And
        report_and(node)
      when Errors::Or
        report_or(node)
      else
        raise "Illegal node: #{node.inspect}"
      end
    end

    def report_empty
      'no error'
    end

    def report_element(element)
      line("#{@path_stack.last}: #{element.message}")
    end

    def report_nested(nested)
      key = nested.key

      segment = if key.is_a?(Expression)
        key.to_s(substitutions: { actual: @path_stack.last })
      else
        "[#{key.inspect}]"
      end

      @path_stack.push(@path_stack.last + segment)
      report_node(nested.node)
      @path_stack.pop
    end

    def report_and(node)
      node.nodes.each { report_node(_1) }
    end

    def report_or(node)
      line('expected at least one error to be absent:')

      node.nodes.each do |n|
        line('- ', newline: false)

        @level += 1
        report_node(n)
        @level -= 1
      end
    end

    def line(message, newline: true)
      message = '  ' * @level + message unless @continue_line
      message += "\n" if newline

      @continue_line = !newline
      @io.print(message)
    end
  end
end
