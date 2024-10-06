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
        errors << "expected an Array but got #{actual.inspect}" unless @negated
        return
      end

      if @array.length != actual.length
        return if @negated

        errors << "expected length of #{@array.length} but got #{actual.length}"
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
        errors << "expected array to not be an equal set to #{@array} but got #{actual}" if missing.empty?
      else
        missing.each { errors << "expected array to include #{_1.inspect}" }
        extra.each { errors[_1] << "unexpected item #{actual[_1].inspect}" }
      end
    end
    protected :check

    def to_s
      "#{'~' if @negated}set(#{@array})"
    end
  end
end
