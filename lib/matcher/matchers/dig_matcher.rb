# frozen_string_literal: true

module Matcher
  class DigMatcher < Base
    def initialize(keys, matcher, optional: false, negated: false)
      super()

      @keys = keys
      @matcher = negated ? ~matcher : matcher
      @original_matcher = matcher
      @optional = optional
      @negated = negated
    end

    def negate
      DigMatcher.new(
        @keys, @original_matcher, optional: @optional, negated: !@negated
      )
    end

    def validate(state, &)
      return validate_negated(state, &) if @negated

      cur = state.actual
      errors = state.errors

      @keys.each do |key|
        key = key.evaluate(state.values) if key.is_a?(Expression)
        is_array = cur.is_a?(Array)

        if is_array
          unless key.is_a?(Integer)
            errors << state.expected(cur).kind_of(Hash)
            return nil
          end
        elsif !cur.is_a?(Hash)
          or_error = state.new_collector.or!
          or_error << state.expected(cur).kind_of(Hash)
          or_error << state.expected(cur).kind_of(Array)
          errors << or_error.error

          return nil
        end

        prev = cur
        cur = cur[key]

        if cur.nil?
          if @optional
            return nil unless is_array ? index?(prev, key) : prev.key?(key)
          elsif is_array
            unless index?(prev, key)
              errors << state.expected(prev).having_index(key)
              return nil
            end
          else
            unless prev.key?(key)
              errors << state.expected(prev).having_key(key)
              return nil
            end
          end
        end

        errors = errors[key]
      end

      errors << yield(@matcher, cur)
    end

    def to_s
      helper = "#{'optional_' if @optional}dig"
      keys = @keys.map(&:inspect).join(", ")
      matcher = Matcher.parenthesize(@original_matcher)

      "#{'~' if @negated}#{helper}(#{keys}) ^ #{matcher}"
    end

    private

    def index?(array, index)
      index.between?(-array.length, array.length - 1)
    end

    def validate_negated(state)
      cur = state.actual
      errors = state.errors

      @keys.each do |key|
        key = key.evaluate(state.values) if key.is_a?(Expression)
        is_array = cur.is_a?(Array)

        return nil if is_array ? !key.is_a?(Integer) : !cur.is_a?(Hash)

        prev = cur
        cur = cur[key]

        if cur.nil?
          if is_array
            unless index?(prev, key)
              errors << state.expected(prev).having_index(key) if @optional
              return nil
            end
          else
            unless prev.key?(key)
              errors << state.expected(prev).having_key(key) if @optional
              return nil
            end
          end
        end

        errors = errors[key]
      end

      errors << yield(@matcher, cur)
    end
  end

  module MatcherBuilding
    ##
    # Matches deeply nested values
    # @example
    #   # matches [0, { a: { "B" => 42 } }] where b: "B", but not []
    #   dig(1, :a, vars[:b]) ^ Integer
    # @param path [Array<Expression>]
    # @param optional [true, false] matches if path doesn't exist when +true+
    # @return [Chain<DigMatcher>]
    def dig(*path, optional: false)
      path.each_with_index do |key, i|
        path[i] = expression_or_value(key)
      end

      Chain.new do |matcher|
        DigMatcher.new(path, matcher, optional:)
      end
    end

    ##
    # Matches deeply nested value only if path exists
    # @example
    #   # matches { a: { b: 1 } } and { a: {} } but
    #   # neither { a: { b: nil } } nor { a: nil }
    #   optional_dig(:a, :b) ^ 1
    # @param path [Array<Expression>]
    # @return [Chain<DigMatcher>]
    def optional_dig(*path)
      dig(*path, optional: true)
    end
  end
end
