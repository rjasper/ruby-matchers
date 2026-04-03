# frozen_string_literal: true

module Matcher
  class AlternativeHashMatcher < Base
    extend Forwardable

    def initialize(hash, partial: false, negated: false)
      super()

      @hash = hash
      @partial = partial
      @negated = negated
      @matcher = build_matcher(hash, partial)
    end

    def_delegator :@matcher, :match

    def ~
      negated = clone
      negated.instance_variable_set(:@matcher, ~@matcher)
      negated.instance_variable_set(:@negated, !@negated)
      negated
    end

    def to_s
      if @partial
        "#{'~' if @negated}partial(#{@hash})"
      elsif @negated
        "neg(#{@hash})"
      else
        @hash.to_s
      end
    end

    private

    def build_matcher(hash, partial)
      includes_others = hash.include?(Others.instance)

      raise "cannot use partial(others => ...)" if partial && includes_others

      kind_of_hash = KindOfMatcher.new(Hash)

      inner_matcher = if hash.empty?
        return kind_of_hash if partial

        empty_matcher
      elsif !partial && !includes_others
        AllMatcher.new([no_extra_keys, hash_matcher])
      else
        hash_matcher
      end

      need_extra_keys = !partial || includes_others
      keys = hash.each_key.map { Optional.value_of(_1) }
      includes_expressions = keys.any?(Expression)

      if need_extra_keys || includes_expressions
        inner_matcher =
          InlineMatcher.new(inner_matcher, negatable: true) do |actual, y|
            expected_keys = if includes_expressions
              values_with_actual = values.merge(actual:)
              key_values = {}
              receiver.session[:key_values] = key_values

              keys.map.with_index do |k, i|
                next k unless k.is_a?(Expression)

                key_values[i] = k.evaluate(values_with_actual)
              end
            else
              keys
            end

            if need_extra_keys
              receiver.session[:extra_keys] = actual.keys - expected_keys
            end

            errors << y[matcher]
          end
      end

      LazyAllMatcher.new([kind_of_hash, inner_matcher])
    end

    def no_extra_keys
      InlineMatcher.new(negatable: true) do |actual|
        extra_keys = receiver.session[:extra_keys]

        if negated?
          errors << "no extra key" if extra_keys.empty?
        else
          extra_keys.each do |key|
            errors[key] << expected(actual).not.having_key(key)
          end
        end
      end
    end

    def empty_matcher
      expression = Call.new(Variable.actual, :empty?)

      ExpressionMatcher.new(expression)
    end

    def hash_matcher
      pair_matchers = @hash.map.with_index do |(key, value), i|
        next others_matcher(value) if key.is_a?(Others)

        value_matcher = @hash[key]
        is_optional = key.is_a?(Optional)
        key = key.value if is_optional

        having_key = if key.is_a?(Expression)
          having_dynamic_key(i)
        else
          having_static_key(key)
        end

        project_matcher = project(key, i, value_matcher)

        if is_optional
          ImplyMatcher.new(having_key, project_matcher)
        else
          LazyAllMatcher.new([having_key, project_matcher])
        end
      end

      if pair_matchers.length == 1
        pair_matchers[0]
      else
        AllMatcher.new(pair_matchers)
      end
    end

    def project(key, index, matcher)
      if key.is_a?(Expression)
        index_call = Call.new(Variable.actual, :[], [key])

        InlineMatcher.new(matcher, negatable: true) do |actual, y|
          value = actual[receiver.session[:key_values][index]]
          errors[index_call] << y[self.matcher, value, key:, parent: actual]
        end
      else
        InlineMatcher.new(matcher, negatable: true) do |actual, y|
          errors[key] << y[self.matcher, actual[key], key:, parent: actual]
        end
      end
    end

    def others_matcher(value_matcher)
      InlineMatcher.new(value_matcher, negatable: true) do |actual, y|
        errors << y[matcher, actual.slice(*receiver.session[:extra_keys])]
      end
    end

    def having_static_key(key)
      InlineMatcher.new(negatable: true) do |actual|
        errors << expected(actual).not_if(negated?).having_key(key) if
          negated? == actual.include?(key)
      end
    end

    def having_dynamic_key(index)
      InlineMatcher.new(negatable: true) do |actual|
        key_value = receiver.session[:key_values][index]

        errors << expected(actual).not_if(negated?).having_key(key_value) if
          negated? == actual.include?(key_value)
      end
    end
  end
end
