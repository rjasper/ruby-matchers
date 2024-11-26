# frozen_string_literal: true

module Matcher
  class NegatedHashMatcher < Base
    def initialize(hash, key: :key, parent: :parent, partial: false)
      super()

      @hash = hash
      @neg_hash = @hash.transform_values(&:~)
      @key = key
      @parent = parent
      @partial = partial
    end

    def ~
      HashMatcher.new(
        @hash,
        key: @key,
        parent: @parent,
        partial: @partial,
      )
    end

    def check(actual)
      return unless actual.is_a?(Hash)
      return if !@partial && actual.keys.any? { !@hash.key?(_1) }

      collector = ErrorCollector.new.or!

      @neg_hash.each do |key, value|
        actual_value = actual[key]

        return if actual_value.nil? && !actual.key?(key)

        result = yield value, actual_value, @key => key, @parent => actual

        return if result.valid?

        collector[key] << result
      end

      errors << collector.node
    end
    protected :check

    def to_s
      if @partial
        "~partial(#{@hash})"
      else
        "neg(#{@hash})"
      end
    end
  end
end
