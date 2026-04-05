# frozen_string_literal: true

module Matcher
  ##
  # Expressions are a central feature of this library. They are used for:
  #
  # - building ad-hoc matchers (e.g. <tt>_ > 10</tt> , +_.even?+ )
  # - tracking where match errors happen
  #   (e.g. <tt>root[:name]: expected ...</tt>)
  # - as parameters for other matchers like +map+ where they take the role of
  #   anonymous functions (e.g. <tt>map(_.to_s, "some_string")</tt> )
  #
  # Helpers (like +map+) use expressions instead of procs because the AST of an
  # Expression can be inspected and transformed. This is useful when building
  # the path and message of errors.
  #
  #   my_expression = Matcher::Expression.build { _ * 21 }
  #   my_expression.evaluate(actual: 2) # => 42
  #   # proc equivalent:
  #   ->(x) { x * 21 }
  #
  # Have a look at {Recorder} where we explain how reorders are used to build
  # expressions.
  #
  # @see Recorder
  class Expression
    extend ExpressionBuilding

    def initialize
      raise "abstract class" if instance_of?(Expression)
    end

    def evaluate_tree(values)
      [evaluate(values)]
    end

    def given_for(values)
      variables.to_h { [_1, values[_1]] }
    end

    def visit
      return to_enum(:visit) unless block_given?

      yield self
    end

    def free_symbol(symbol)
      parameters = ExpressionWalker.each_block(self).flat_map do |block|
        block.parameters.map { |_type, name| name }
      end

      identifiers = (variables + parameters).to_set

      return symbol unless identifiers.include?(symbol)

      i = 2
      loop do
        symbol_i = :"#{symbol}#{i}"

        return symbol_i unless identifiers.include?(symbol_i)

        i += 1
      end
    end

    OPERATOR_PRECEDENCE = begin
      precedence = {}

      # see https://docs.ruby-lang.org/en/master/syntax/precedence_rdoc.html
      [
        %i[! ~ +@],
        %i[**],
        %i[-@],
        %i[* / %],
        %i[+ -],
        %i[<< >>],
        %i[&],
        %i[| ^],
        %i[> >= < <=],
        %i[<=> == === != =~ !~],
        %i[&&],
        %i[||],
        %i[..],
        %i[modifier_rescue],
      ].each_with_index do |operators, index|
        operators.each { precedence[_1] = index }
      end

      precedence.freeze
    end

    def precedence
      # highest precedence, won't need parentheses
      -1
    end

    def parenthesize(precedence, when_equal)
      # Parenthesize if own precedence is lower than the other. In some
      # situations (as right hand side or for non-associative operators) we also
      # parenthesize when precedence is equal.

      need_parentheses = if when_equal
        self.precedence >= precedence
      else
        self.precedence > precedence
      end

      need_parentheses ? "(#{self})" : to_s
    end

    def inspect
      to_s
    end

    def to_recorder
      Recorder.new(self)
    end
  end
end
