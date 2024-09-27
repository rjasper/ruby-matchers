# frozen_string_literal: true

module Matcher
  class NegatedHashMatcher < Base
    def initialize(hash, key: :key, parent: :parent, all_entries: true)
      super()

      @hash = hash
      @neg_hash = @hash.transform_values(&:~)
      @key = key
      @parent = parent
      @all_entries = all_entries
    end

    def negated
      HashMatcher.new(
        @hash,
        key: @key,
        parent: @parent,
        all_entries: @all_entries,
      )
    end

    def check(actual:, **)
      return unless actual.is_a?(Hash)
      return if @all_entries && actual.keys.any? { !@hash.key?(_1) }

      collector = Errors::Collector.new.or!

      @neg_hash.each do |key, value|
        actual_value = actual[key]

        return if actual_value.nil? && !actual.key?(key)

        result = value.match(**, actual: actual_value, @key => key, @parent => actual)

        return if result.valid?

        collector[key] << result
      end

      errors << collector.node
    end
    protected :check

    def to_s
      if @all_entries
        "neg(#{self.~})"
      else
        "partial_entries(#{self.~})"
      end
    end
  end
end
