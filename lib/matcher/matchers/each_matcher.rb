# frozen_string_literal: true

module Matcher
  class EachMatcher < Base
    def initialize(matcher, index: :index, key: :key, value: :value, parent: :parent)
      super()

      @matcher = matcher
      @index = index
      @key = key
      @value = value
      @parent = parent
    end

    def check(actual:, **values)
      unless actual.respond_to?(:each)
        errors << "expected to respond to \"each\" but got #{actual.inspect}"
        return
      end

      if actual.is_a?(Hash)
        check_hash(actual, values)
      else
        check_array(actual, values)
      end
    end
    protected :check

    def inspect
      "each(#{@matcher.inspect})"
    end

    private

    def check_array(array, values)
      array.each.with_index do |item, i|
        errors[i] << @matcher.match(**values, actual: item, @index => i, @parent => array)
      end
    end

    def check_hash(hash, values)
      hash.each do |key, value|
        errors[key] << @matcher.match(
          **values,
          actual: [key, value],
          @key => key,
          @value => value,
          @parent => hash,
        )
      end
    end
  end
end
