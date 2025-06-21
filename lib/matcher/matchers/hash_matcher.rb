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

      expected_keys = @hash.keys.map { _1.is_a?(Optional) ? _1.value : _1 }
      extra_keys = actual.keys - expected_keys

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

        is_optional = key.is_a?(Optional)
        key = key.value if is_optional
        actual_value = actual[key]

        if actual_value.nil? && !actual.key?(key)
          errors << expected.having_key(key) unless is_optional
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
      hash = hash.transform_values { partial_r_helper(_1) }
      HashMatcher.new(hash, partial: true)
    end

    def partial_r_helper(value)
      if ExpressionRecorder.recorder?(value) || !value.is_a?(Hash)
        of(value)
      else
        partial_r(value)
      end
    end
    private :partial_r_helper
  end
end
