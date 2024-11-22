# frozen_string_literal: true

module Matcher
  class ExpressionMatcher
    module MessageRules
      include RuleSet::Definition

      # binary standard expression
      standard_ops = %i[== != < > <= >= <=> =~ !~ equal? is_a? kind_of? instance_of? respond_to? key? include? in?]
      message method_hole(:call, _, standard_ops, const(:operand)) do |v, e|
        case e[:call].method
        when :<
          standard_message.lower_than(v[:operand])
        when :>
          standard_message.greater_than(v[:operand])
        when :<=
          standard_message.lower_or_equal_than(v[:operand])
        when :>=
          standard_message.greater_or_equal_than(v[:operand])
        when :<=>
          # <=> returns nil if operands are not comparable
          standard_message.comparable_to(v[:operand])
        when :==
          standard_message.equal(v[:operand])
        when :!=
          standard_message.not.equal(v[:operand])
        when :=~
          standard_message.matching(v[:operand])
        when :!~
          standard_message.not.matching(v[:operand])
        when :equal?
          standard_message.same(v[:operand])
        when :is_a?, :kind_of?
          standard_message.kind_of(v[:operand])
        when :instance_of?
          standard_message.instance_of(v[:operand])
        when :respond_to?
          standard_message.responding_to(v[:operand])
        when :key?
          standard_message.having_key(v[:operand])
        when :include?
          standard_message.including(v[:operand])
        when :in?
          standard_message.in(v[:operand])
        else
          raise "Unexpected method: #{e[:call].method}"
        end
      end

      # predicate
      message method_hole(:predicate, _, -> { _1.end_with?('?') }) do |_v, e|
        standard_message.predicate(e[:predicate].method)
      end

      # flip
      transform(
        method_hole(
          :call,
          const(:operand),
          %i[== != < > <= >= equal? include? in?],
          capture(:actual, _),
        ),
      ) do |m|
        method = m[:call].expression.method

        flipped_method =
          case method
          when :< then :>
          when :> then :<
          when :<= then :>=
          when :>= then :<=
          when :include? then :in?
          when :in? then :include?
          else
            method
          end

        call(m[:call], m[:actual], flipped_method, m[:operand])
      end

      # length
      message capture(:act, _.length) == const(:exp) do |v|
        standard_message.length_of(v[:exp], v[:act])
      end

      # between
      message _.between?(const(:min), const(:max)) do |v|
        standard_message.between(v[:min], v[:max])
      end

      # truthy
      message _ do
        standard_message.truthy
      end

      # transform !
      transform !hole(:expression), negate: true do |m|
        m[:expression]
      end

      # transform instance_of?
      transform(
        hole(:obj).class == hole(:class),
        hole(:class) == hole(:obj).class,
      ) do |m|
        call(m[:root], m[:obj], :instance_of?, m[:class])
      end

      # transform between?
      transform(
        lo { (hole(:value) >= hole(:min)) & (hole(:value) <= hole(:max)) },
      ) do |m|
        call(m[:root], m[:value], :between?, m[:min], m[:max])
      end

      # transform comparison
      transform(
        method_hole(:compare, hole(:lhs) <=> hole(:rhs), %i[== != < > <= >=], 0),
      ) do |m|
        call(m[:compare], m[:lhs], m[:compare].expression.method, m[:rhs])
      end

      # length expression
      message capture(:act, hole(:object).length) == hole(:exp) do |v, e|
        expression_message.length_of(e[:object], v[:exp], v[:act], given)
      end

      # match regexp at
      message(
        method_hole(
          :comparison,
          capture(:pos, hole(:lhs) =~ hole(:rhs)),
          %i[== != < > <= >=],
          hole(:operand),
        ),
      ) do |v, e|
        expression, value, pattern =
          decompose_pattern_matching(e[:lhs], e[:rhs], v[:lhs], v[:rhs])

        if expression
          expression_message.match_at(
            expression,
            value,
            pattern,
            v[:pos],
            e[:comparison].method,
            v[:operand],
            given,
          )
        else
          expression_message.truthy(e[:comparison], v[:comparison], given)
        end
      end

      # comparison expression
      message method_hole(:comparison, hole(:lhs), %i[== != < > <= >=], hole(:rhs)) do |v, e|
        expression_message.comparison(e[:comparison], v[:lhs], v[:rhs], given)
      end

      # general binary expression
      general_ops = %i[<=> equal? is_a? kind_of? instance_of? respond_to? key? include? in?]
      message method_hole(:call, hole(:lhs), general_ops, hole(:rhs)) do |v, e|
        case e[:call].method
        when :<=>
          # <=> returns nil if operands are not comparable
          expression_message.comparable_to(e[:lhs], v[:lhs], v[:rhs], given)
        when :equal?
          expression_message.same(e[:lhs], e[:rhs], v[:lhs], v[:rhs], given)
        when :is_a?, :kind_of?
          expression_message.kind_of(e[:lhs], v[:lhs], v[:rhs], given)
        when :instance_of?
          expression_message.instance_of(e[:lhs], v[:lhs], v[:rhs], given)
        when :respond_to?
          expression_message.responding_to(e[:lhs], v[:lhs], v[:rhs], given)
        when :key?
          expression_message.having_key(e[:lhs], v[:lhs], v[:rhs], given)
        when :include?
          expression_message.including(e[:lhs], v[:lhs], v[:rhs], given)
        when :in?
          expression_message.in(e[:lhs], v[:lhs], v[:rhs], given)
        else
          raise "Unexpected method: #{e[:call].method}"
        end
      end

      # predicate expression
      message method_hole(:predicate, hole(:receiver), -> { _1.end_with?('?') }) do |v, e|
        expression_message.predicate(e[:receiver], v[:receiver], e[:predicate].method, given)
      end

      # match regexp
      message method_hole(:operator, hole(:lhs), %i[=~ !~], hole(:rhs)) do |v, e|
        expression, value, pattern =
          decompose_pattern_matching(e[:lhs], e[:rhs], v[:lhs], v[:rhs])

        if expression
          negated = @negated ^ (e[:operator].method == :!~)

          expected.namespace(:expression).not_if(negated)
            .matching(expression, value, pattern, given)
        else
          expression_message.truthy(e[:operator], v[:operator], given)
        end
      end

      # between expression
      message hole(:value).between?(hole(:min), hole(:max)) do |v, e|
        expression_message.between(e[:value], v[:value], v[:min], v[:max], given)
      end

      # any expression
      message hole(:expression) do |v, e|
        expression_message.truthy(e[:expression], v[:expression], given)
      end
    end
  end
end
