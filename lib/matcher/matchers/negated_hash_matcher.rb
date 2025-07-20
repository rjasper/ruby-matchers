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
      @includes_others = hash.include?(Others.instance)
      @includes_optionals = hash.each_key.any? { _1.is_a?(Optional) }
      @includes_expressions = hash.each_key.any? { _1.is_a?(Expression) }

      raise 'cannot use partial(others => ...)' if @partial && @includes_others
    end

    def others
      return nil unless @includes_others

      @others ||= Matcher.of(@neg_hash[Others.instance])
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

      if @hash.empty?
        if @partial
          errors << report.kind_of(Hash)
        elsif actual.empty?
          errors << report.predicate(:empty?)
        end

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

      # expected_keys = @hash.keys.map { _1.is_a?(Optional) ? _1.value : _1 }
      extra_keys = actual.keys - expected_keys

      return if !@partial && !@includes_others && !extra_keys.empty?

      collector = new_collector.or!

      @neg_hash.each_with_index do |(key, value), i|
        if key.is_a?(Others)
          result = yield(others, actual.slice(*extra_keys))

          return if result.valid?

          collector << result

          next
        end

        is_optional = key.is_a?(Optional)
        key = key.value if is_optional
        error_key = key
        key = expression_values[i] if key.is_a?(Expression)
        actual_value = actual[key]

        if actual_value.nil? && !actual.key?(key)
          next if is_optional

          return
        end

        result = yield value, actual_value, @key => key, @parent => actual

        return if result.valid?

        error_key = key_call_for(error_key) if error_key.is_a?(Expression)

        collector[error_key] << result
      end

      errors << if collector.empty?
        report.predicate(:empty?)
      else
        collector.error
      end
    end
    protected :check

    def to_s
      if @partial
        "~partial(#{@hash})"
      else
        "neg(#{@hash})"
      end
    end

    private

    def key_call_for(key)
      Call.new(Variable.actual, :[], [key])
    end
  end
end
