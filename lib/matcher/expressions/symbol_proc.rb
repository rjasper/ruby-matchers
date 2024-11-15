# frozen_string_literal: true

module Matcher
  class SymbolProc
    def initialize(proc_or_symbol)
      case proc_or_symbol
      when Symbol
        @symbol = proc_or_symbol
        @proc = proc_or_symbol.to_proc
      when Proc
        @proc = proc_or_symbol
      else
        raise "Expected Proc or Symbol, got #{proc_or_symbol.inspect}"
      end
    end

    def ==(other)
      equal?(other) || other.instance_of?(SymbolProc) && symbol == other.symbol
    end
    alias eql? ==

    def hash
      symbol.hash
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
