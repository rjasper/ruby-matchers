# frozen_string_literal: true

module Matcher
  class HashMatcher < Base
    def initialize(hash, key: :key, parent: :parent, partial: false)
      super()

      @hash = hash
      @key = key
      @parent = parent
      @partial = partial
      @includes_others = hash.include?(Others.instance)

      raise 'cannot use partial(others => ...)' if @partial && @includes_others
    end

    def others
      return nil unless @includes_others

      @others ||= Matcher.of(@hash[Others.instance])
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

      extra_keys = actual.keys - @hash.keys

      if !@partial && !@includes_others
        extra_keys.each do |key|
          errors[key] << expected.not.having_key(key)
        end
      end

      @hash.each do |key, value|
        if key.is_a?(Others)
          errors << yield(others, actual.slice(*extra_keys))

          next
        end

        actual_value = actual[key]

        if actual_value.nil? && !actual.key?(key)
          errors << expected.having_key(key)
        else
          errors[key] << yield(value, actual_value, @key => key, @parent => actual)
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
  end

  module MatcherBuilding
    def partial(hash)
      hash = hash.transform_values { of(_1) }
      HashMatcher.new(hash, partial: true)
    end

    def partial_r(hash)
      return of(hash) if ExpressionRecorder.recorder?(hash) || !hash.is_a?(Hash)

      hash = hash.transform_values { partial_r(_1) }
      HashMatcher.new(hash, partial: true)
    end
  end
end
