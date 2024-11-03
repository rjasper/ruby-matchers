# frozen_string_literal: true

module Matcher
  class SymbolProc
    def initialize(proc)
      @proc = proc
    end

    def symbol
      @symbol ||= begin
        recorder = ExpressionRecorder.new(nil)
        result = @proc.call(recorder)
        expression = ExpressionRecorder.to_expression(result)

        expression.method
      end
    end

    def to_proc
      @proc
    end

    def to_s
      "#{symbol.inspect}.to_proc"
    end
    alias inspect to_s
  end
end
