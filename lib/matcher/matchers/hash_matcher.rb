# frozen_string_literal: true

module Matcher
  class HashMatcher < Base
    def initialize(hash, key: :key, parent: :parent, partial: false)
      super()

      @hash = hash
      @key = key
      @parent = parent
      @partial = partial
    end

    def ~
      NegatedHashMatcher.new(
        @hash,
        key: @key,
        parent: @parent,
        partial: @partial,
      )
    end

    def check(actual)
      unless actual.is_a?(Hash)
        errors << expected.kind_of(Hash)
        return
      end

      check_all_entries(actual) unless @partial

      @hash.each do |key, value|
        actual_value = actual[key]

        errors[key] << if actual_value.nil? && !actual.key?(key)
          expected.having_key(key)
        else
          yield(value, actual_value, @key => key, @parent => actual)
        end
      end
    end
    protected :check

    def to_s
      if @partial
        "partial(#{@hash})"
      else
        @hash.to_s
      end
    end

    private

    def check_all_entries(actual)
      extra_keys = actual.keys - @hash.keys
      extra_keys.each do |key|
        errors[key] << expected.not.having_key(key)
      end
    end
  end
end
