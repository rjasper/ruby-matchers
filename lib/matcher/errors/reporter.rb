# frozen_string_literal: true

require "stringio"

module Matcher
  class Reporter
    ##
    # Formats an error tree as a human-readable string
    # @example
    #   errors = Matcher.build { Integer }.match("foo")
    #   puts Reporter.report(errors)
    #   # > root: expected a kind of Integer but got "foo"
    # @param error [Error] the error tree from {Base#match}
    # @return [String]
    def self.report(error)
      new.report(error)
    end

    def initialize
      @level = 0
      @continue_line = false
      @path_stack = ["root"]
      @phrasing = ExpectedPhrasing.phrasing
    end

    def report(error)
      @io = StringIO.new

      report_error(error)

      string = @io.string
      @io.close
      @io = nil

      string
    end

    private

    def report_error(error)
      case error
      when EmptyError
        report_empty
      when ElementError
        report_element(error)
      when NestedError
        report_nested(error)
      when AndError
        report_and(error)
      when OrError
        report_or(error)
      else
        raise "Illegal error: #{error.inspect}"
      end
    end

    def report_empty
      "no error"
    end

    def report_element(element)
      message = element.message

      if message.is_a?(Message)
        message = @phrasing.call(@path_stack.last, message)
      end

      line("#{@path_stack.last}: #{message}")
    end

    def report_nested(nested)
      path = NestedError.key_to_s(nested.key, @path_stack.last)

      @path_stack.push(path)
      report_error(nested.child)
      @path_stack.pop
    end

    def report_and(error)
      error.children.each { report_error(_1) }
    end

    def report_or(error)
      line("expected at least one error to be absent:")

      error.children.each do |n|
        line("- ", newline: false)

        @level += 1
        report_error(n)
        @level -= 1
      end
    end

    def line(message, newline: true)
      message = "  " * @level + message unless @continue_line
      message += "\n" if newline

      @continue_line = !newline
      @io.print(message)
    end
  end
end
