# frozen_string_literal: true

module Matcher
  class HashMatcher < Base
    def initialize(hash, partial: false)
      super()

      @hash = hash
      @partial = partial
      @includes_others = hash.include?(Others.instance)
      @includes_optionals = hash.each_key.any? { _1.is_a?(Optional) }
      @includes_expressions = hash.each_key.any? { _1.is_a?(Expression) }

      raise 'cannot use partial(others => ...)' if @partial && @includes_others
    end

    def others
      return nil unless @includes_others

      @others ||= Matcher.of(@hash[Others.instance])
    end

    def ~
      NegatedHashMatcher.new(@hash, partial: @partial)
    end

    def check(actual)
      unless actual.is_a?(Hash)
        errors << expected.kind_of(Hash)
        return
      end

      if @includes_expressions
        values_with_actual = values.merge(actual:)
        expression_values = {}

        @hash.each_key.with_index do |key, i|
          key = key.value if key.is_a?(Optional)
          expression_values[i] = key.evaluate(values_with_actual) if key.is_a?(Expression)
        end
      end

      expected_keys = if @includes_optionals || @includes_expressions
        @hash.keys.map.with_index do |k, i|
          k = k.value if k.is_a?(Optional)
          k = expression_values[i] if k.is_a?(Expression)
          k
        end
      else
        @hash.keys
      end

      extra_keys = actual.keys - expected_keys

      if !@partial && !@includes_others
        extra_keys.each do |key|
          errors[key] << expected.not.having_key(key)
        end
      end

      @hash.each_with_index do |(key, value), i|
        if key.is_a?(Others)
          errors << yield(others, actual.slice(*extra_keys))

          next
        end

        is_optional = key.is_a?(Optional)
        key = key.value if is_optional
        error_key = key
        key = expression_values[i] if key.is_a?(Expression)
        actual_value = actual[key]

        if actual_value.nil? && !actual.key?(key)
          errors << expected.having_key(key) unless is_optional
        else
          error = yield(value, actual_value, key:, parent: actual)

          next if error.valid?

          error_key = key_call_for(error_key) if error_key.is_a?(Expression)

          errors[error_key] << error
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

    def key_call_for(key)
      Call.new(Variable.actual, :[], [key])
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
