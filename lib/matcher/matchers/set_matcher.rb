# frozen_string_literal: true

module Matcher
  class SetMatcher < Base
    def initialize(array, parent: :parent, negated: false)
      super()

      @array = array
      @parent = parent
      @negated = negated
    end

    def ~
      SetMatcher.new(@array, parent: @parent, negated: !@negated)
    end

    def check(actual)
      unless actual.is_a?(Array)
        errors << expected.kind_of(Array) unless @negated
        return
      end

      if @array.length != actual.length
        return if @negated

        errors << expected.length_of(@array.length)
      end

      missing = @array.clone
      extra = []

      actual.each_with_index do |element, i|
        break if missing.empty?

        index = missing.find_index do |m|
          yield(m, element, @parent => actual).valid?
        end

        if index
          missing.delete_at(index)
        else
          extra << i
        end
      end

      if @negated
        # when negated then missing.empty? <=> extra.empty?
        errors << report(namespace: :set).equal(@array) if missing.empty?
      else
        missing.each { errors << expected(_1).included_in(actual) }
        extra.each { errors[_1] << report(actual[_1]).included_in(actual) }
      end
    end
    protected :check

    def to_s
      "#{'~' if @negated}set(#{@array})"
    end
  end
end
