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

      extra_keys = actual.keys - @hash.keys

      return if !@partial && !@includes_others && !extra_keys.empty?

      collector = new_collector.or!

      @neg_hash.each do |key, value|
        if key.is_a?(Others)
          result = yield(others, actual.slice(*extra_keys))

          return if result.valid?

          collector << result

          next
        end

        actual_value = actual[key]

        return if actual_value.nil? && !actual.key?(key)

        result = yield value, actual_value, @key => key, @parent => actual

        return if result.valid?

        collector[key] << result
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
  end
end
