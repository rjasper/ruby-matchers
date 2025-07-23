# frozen_string_literal: true

module Matcher
  class State
    def initialize(values)
      @values = values
    end

    attr_reader :values

    def actual
      @values[:actual]
    end

    def errors
      @error_collector ||= new_collector
    end

    def new_collector
      ErrorCollector.new(@values)
    end

    def result
      @error_collector&.error || EmptyError.instance
    end
  end
end
