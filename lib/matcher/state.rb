# frozen_string_literal: true

module Matcher
  class State
    def initialize(values, boolean: false)
      @values = values
      @boolean = boolean
    end

    attr_reader :values

    def boolean?
      @boolean
    end

    def actual
      @values[:actual]
    end

    def errors
      @error_collector ||= new_collector
    end

    def new_collector
      @boolean ? BooleanCollector.new : ErrorCollector.new
    end

    def result
      @error_collector&.error || EmptyError.instance
    end

    def report(actual = self.actual)
      StandardMessageBuilder.new(false, actual)
    end

    def expected(actual = self.actual)
      StandardMessageBuilder.new(true, actual)
    end
  end
end
