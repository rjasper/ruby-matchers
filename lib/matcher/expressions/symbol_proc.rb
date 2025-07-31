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
        @symbol = get_symbol(proc_or_symbol)
      else
        raise "Expected Proc or Symbol, got #{proc_or_symbol.inspect}"
      end
    end

    attr_reader :symbol

    def ==(other)
      equal?(other) || other.instance_of?(SymbolProc) && @symbol == other.symbol
    end
    alias eql? ==

    def hash
      [self.class, @symbol].hash
    end

    def variables
      []
    end

    def to_proc
      @proc
    end

    def to_s
      "&#{@symbol.inspect}"
    end
    alias inspect to_s

    private

    def get_symbol(proc)
      receiver = Variable.actual # could be any
      recorder = Recorder.new(receiver)
      result = proc.call(recorder)
      expression = Recorder.to_expression(result)

      expression.method
    end
  end
end
