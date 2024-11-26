# frozen_string_literal: true

module Matcher
  class Reporter
    def self.report(node)
      new.report(node)
    end

    def initialize
      @level = 0
      @continue_line = false
      @path_stack = ['root']
      @phrasing = ExpectedPhrasing.phrasing
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
      when EmptyError
        report_empty
      when ElementError
        report_element(node)
      when NestedError
        report_nested(node)
      when AndError
        report_and(node)
      when OrError
        report_or(node)
      else
        raise "Illegal node: #{node.inspect}"
      end
    end

    def report_empty
      'no error'
    end

    def report_element(element)
      message = element.message
      message = @phrasing.call(@path_stack.last, message) if message.is_a?(ErrorMessage)

      line("#{@path_stack.last}: #{message}")
    end

    def report_nested(nested)
      path = NestedError.key_to_s(nested.key, @path_stack.last)

      @path_stack.push(path)
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
