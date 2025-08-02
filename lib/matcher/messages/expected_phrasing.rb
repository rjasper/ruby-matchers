# frozen_string_literal: true

module Matcher
  class ExpectedPhrasing < Phrasing
    define(:truthy) do
      verb = verb(negated: true)
      truthy_or_falsy = negated ? 'truthy' : 'falsy'

      "#{verb} a #{truthy_or_falsy} value but got #{actual.inspect}"
    end

    define(:same) do |object|
      "#{verb} same as #{object.inspect} (id=#{object.object_id})" \
        "#{" but got #{actual.inspect} (id=#{actual.object_id})" if negated}"
    end

    define(:equal) do |value|
      if negated
        "#{verb} #{value.inspect} but got #{actual.inspect}"
      else
        "#{verb} #{actual.inspect}"
      end
    end

    define(:lower_than) do |operand|
      if negated || (actual <=> operand).nil?
        "#{verb} a value < #{operand.inspect} but got #{actual.inspect}"
      else
        phrase_negated(:greater_or_equal_than, operand)
      end
    end

    define(:greater_than) do |operand|
      if negated || (actual <=> operand).nil?
        "#{verb} a value > #{operand.inspect} but got #{actual.inspect}"
      else
        phrase_negated(:lower_or_equal_than, operand)
      end
    end

    define(:lower_or_equal_than) do |operand|
      if negated || (actual <=> operand).nil?
        "#{verb} a value <= #{operand.inspect} but got #{actual.inspect}"
      else
        phrase_negated(:greater_than, operand)
      end
    end

    define(:greater_or_equal_than) do |operand|
      if negated || (actual <=> operand).nil?
        "#{verb} a value >= #{operand.inspect} but got #{actual.inspect}"
      else
        phrase_negated(:lower_than, operand)
      end
    end

    define(:comparable_to) do |operand|
      "#{verb} a value comparable to #{operand.inspect} but got #{actual.inspect}"
    end

    define(:between) do |min, max, exclude_end: false|
      "#{verb} value to be between #{min.inspect} and " \
        "#{max.inspect}#{' (exclusive)' if exclude_end} but got #{actual.inspect}"
    end

    define(:length_of) do |exp, act|
      "#{verb} length of #{exp}#{" but was #{act}" if negated}"
    end

    define(:having_key) do |key|
      "#{verb} to include key #{key.inspect} but got #{actual.inspect}"
    end

    define(:having_index) do |index|
      "#{verb} to have index #{index.inspect} but got #{actual.inspect}"
    end

    define(:exist) do
      "#{verb} index to exist#{" but got #{actual.inspect}" unless negated}"
    end

    define(:in) do |collection|
      "#{verb} object to be included in #{collection.inspect} but got #{actual.inspect}"
    end

    define(:including) do |item|
      "#{verb} #{item.inspect} to be included but got #{actual.inspect}"
    end

    define(:matching) do |pattern|
      "#{verb} value to match #{pattern.inspect} but got #{actual.inspect}"
    end

    define(:valid_format) do |format|
      "#{verb} a valid #{format} string but got #{actual.inspect}"
    end

    define(:instance_of) do |klass|
      "#{verb} an instance of #{klass} but got #{actual.inspect}"
    end

    define(:kind_of) do |klass|
      "#{verb} a kind of #{klass} but got #{actual.inspect}"
    end

    define(:responding_to) do |method|
      "#{verb} an object responding to `#{method}' but got #{actual.inspect}"
    end

    define(:predicate) do |predicate|
      predicate = predicate.to_s.delete_suffix('?')

      "#{verb} value to be #{predicate} but got #{actual.inspect}"
    end

    define(:described_by) do |description|
      "#{verb} #{description} but got #{actual.inspect}"
    end

    namespace(:expression) do
      define(:truthy) do |expression, value, given|
        verb = verb(negated: true)
        truthy_or_falsy = negated ? 'truthy' : 'falsy'

        "#{verb} #{expression} to be #{truthy_or_falsy} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:same) do |left_expression, right_expression, left, right, given|
        "#{verb} #{left_expression} to be same as #{right_expression} " \
          "but got #{left.inspect} (id=#{left.object_id})" \
          "#{" and #{right.inspect} (id=#{right.object_id})" if negated}" \
          "#{where_text(given, left_expression, right_expression)}"
      end

      negated_comparisons =
        { :== => :!=, :!= => :==, :< => :>=, :> => :<=, :<= => :>, :>= => :< }

      define(:comparison) do |expression, left, right, given|
        can_negate = !negated &&
          (method = negated_comparisons[expression.method]) &&
          (%i[== !=].include?(method) || left <=> right)

        verb = if can_negate
          expression = Call.new(
            expression.receiver,
            method,
            expression.args,
            expression.kwargs,
          )

          verb(negated: true)
        else
          self.verb
        end

        "#{verb} #{expression} but got " \
          "#{left.inspect} #{expression.method} #{right.inspect}" \
          "#{where_text(given, expression.receiver, expression.args[0])}"
      end

      define(:comparable_to) do |expression, value, operand, given|
        "#{verb} #{expression} to be comparable to #{operand.inspect} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:between) do |expression, value, min, max, given|
        "#{verb} #{expression} to be between #{min.inspect} and #{max.inspect} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:length_of) do |expression, exp, act, given|
        "#{verb} #{expression} to have length of #{exp}" \
          "#{" but was #{act}" if negated}#{where_text(given, expression)}"
      end

      define(:having_key) do |expression, value, key, given|
        "#{verb} #{expression} to include key #{key.inspect} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:in) do |expression, value, collection, given|
        "#{verb} #{expression} to be included in #{collection.inspect} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:including) do |expression, value, item, given|
        "#{verb} #{expression} to include #{item.inspect} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:matching) do |expression, value, pattern, given|
        "#{verb} #{expression} to match #{pattern.inspect} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      match_at_words = {
        :== => 'at',
        :!= => 'not at',
        :< => 'before',
        :> => 'after',
        :<= => 'at or before',
        :>= => 'at or after',
      }

      define(:match_at) do |expression, value, pattern, position, comparison, operand, given|
        comparison_word = match_at_words[comparison]

        message = String.new
        message << "#{verb} #{expression} to match #{pattern.inspect} #{comparison_word} #{operand} "
        message << "but was at #{position} " if
          operand != position || comparison != (negated ? :!= : :==)
        message << "for #{value.inspect}#{where_text(given, expression)}"

        message
      end

      define(:instance_of) do |expression, value, klass, given|
        "#{verb} #{expression} to be an instance of #{klass} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:kind_of) do |expression, value, klass, given|
        "#{verb} #{expression} to be a kind of #{klass} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:responding_to) do |expression, value, method, given|
        "#{verb} #{expression} to respond to `#{method}' " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:predicate) do |expression, value, predicate, given|
        predicate = predicate.to_s.delete_suffix('?')

        "#{verb} #{expression} to be #{predicate} " \
          "but got #{value.inspect}#{where_text(given, expression)}"
      end

      define(:raising) do |expression, error, given|
        "#{verb} #{expression} to raise #{error.class}" \
          "#{where_text(given, expression)}: #{error.message}"
      end
    end

    namespace(:negated) do
      define(:valid) do |matcher|
        "#{verb} #{matcher} to be valid but got #{actual.inspect}"
      end
    end

    namespace(:block) do
      define(:satisfied) do |block_location|
        "#{verb} to satisfy condition #{block_location} but got #{actual.inspect}"
      end
    end

    namespace(:imply_some) do
      def x_conditions(count)
        case count
        when :any
          'any condition'
        when 1
          'one condition'
        else
          "#{count} conditions"
        end
      end
      private :x_conditions

      define(:no_condition_satisfied) do |conditions, count|
        "#{negated_verb} to satisfy #{x_conditions(count)} but got #{actual.inspect} and met none of these: #{join(conditions)}"
      end

      define(:x_conditions_satisfied) do |conditions, count|
        "#{negated_verb} to satisfy #{x_conditions(count)} but got #{actual.inspect} and met these: #{join(conditions)}"
      end
    end

    namespace(:iso8601) do
      define(:valid) do
        "#{verb} an ISO 8601 string but got #{actual.inspect}"
      end
    end

    namespace(:reference) do
      define(:cyclic) do
        "#{verb} a cyclic structure" \
          "#{' but actual has already been visited' unless negated}"
      end

      define(:failed_from_cache) do
        'actual has already failed before'
      end
    end

    namespace(:set) do
      define(:equal) do |set|
        "#{verb} object to be an equal set to #{set.inspect} but got #{actual.inspect}"
      end

      define(:including_matchable_by) do |matcher|
        "#{verb} to include an element matching #{matcher} but got #{actual.inspect}"
      end
    end

    private

    def verb(negated: self.negated)
      # A message says what actual is but expected says what it is not. That's why
      # the verb is counter-intuitively negated.

      negated ? 'expected' : 'did not expect'
    end

    def negated_verb
      verb(negated: !negated)
    end

    def join(objects)
      objects.map(&:to_s).join(', ')
    end

    def where_text(values, *expressions)
      return '' if values.empty?

      substitutions = Expression.default_substitutions

      except = expressions.filter_map { _1.symbol if _1.is_a?(Variable) }
      symbols = expressions.flat_map(&:variables).uniq - except

      return '' if symbols.empty?

      list = symbols
        .map { "#{substitutions[_1] || _1} = #{values.fetch(_1).inspect}" }
        .join(', ')

      ", where #{list}"
    end
  end
end
