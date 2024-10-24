# frozen_string_literal: true

module Matcher
  class ExpectedPhrasing < AbstractPhrasing
    define(:between) do |range|
      "#{verb} #{actual.inspect} to be between #{range}"
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

    define(:truthy) do
      if negated
        "#{verb} a truthy value but got #{actual.inspect}"
      else
        phrase_negated(:falsy)
      end
    end

    define(:falsy) do
      if negated
        "#{verb} a falsy value but got #{actual.inspect}"
      else
        phrase_negated(:truthy)
      end
    end

    define(:described_by) do |description|
      "#{verb} #{description} but got #{actual.inspect}"
    end

    define(:having_key) do |key|
      "#{verb} to include key #{key.inspect} but got #{actual.inspect}"
    end

    define(:instance_of) do |klass|
      "#{verb} an instance of #{klass} but got #{actual.inspect}"
    end

    define(:kind_of) do |klass|
      "#{verb} a kind of #{klass} but got #{actual.inspect}"
    end

    define(:length_of) do |length|
      "#{verb} length of #{length} but got #{actual.length}"
    end

    define(:matching) do |pattern|
      "#{verb} #{actual.inspect} to match #{pattern.inspect}"
    end

    define(:included_in) do |collection|
      "#{verb} #{actual.inspect} to be included in #{collection.inspect}"
    end

    define(:responding_to) do |method|
      "#{verb} #{actual.inspect} to respond to #{method.inspect}"
    end

    define(:predicate) do |predicate|
      predicate = predicate.to_s.delete_suffix('?')

      "#{verb} value to be #{predicate} but got #{actual.inspect}"
    end

    namespace(:block) do
      define(:satisfied) do |block_location|
        "#{verb} to satisfy condition #{block_location} but got #{actual.inspect}"
      end
    end

    namespace(:imply_one) do
      define(:no_condition_satisfied) do |conditions|
        "#{negated_verb} #{actual.inspect} to satisfy one of these conditions: #{join(conditions)}"
      end

      define(:multiple_conditions_satisfied) do |conditions|
        "#{negated_verb} #{actual.inspect} to satisfy only one condition, but met these: #{join(conditions)}"
      end
    end

    namespace(:iso8601) do
      define(:valid) do
        "#{verb} an ISO 8601 string but got #{actual.inspect}"
      end
    end

    namespace(:negated) do
      define(:valid) do |matcher|
        "#{verb} #{matcher} to be valid but got #{actual.inspect}"
      end
    end

    namespace(:reference) do
      define(:cyclic) do
        if negated
          "#{verb} a cyclic structure but actual has already been visited"
        else
          "#{verb} a valid cyclic structure"
        end
      end

      define(:failed_from_cache) do
        'actual has already failed before'
      end
    end

    namespace(:set) do
      define(:equal) do |set|
        "#{verb} #{actual.inspect} to be an equal set to #{set.inspect}"
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
  end
end
