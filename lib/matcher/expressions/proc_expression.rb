# frozen_string_literal: true

module Matcher
  class ProcExpression < Expression
    def initialize(block, substitution: nil, to_s: false)
      super()

      check_parameters(block.parameters)

      @block = block
      @substitution = substitution
      @to_s = to_s
    end

    attr_reader :block, :substitution

    def check_parameters(parameters)
      parameters.each_with_index do |(type, name), i|
        case type
        when :req, :opt
          raise 'ProcExpression cannot have more than 1 arg' if i > 0
        when :keyreq, :key
          raise 'ProcExpression cannot have an kwarg called "actual"' if name == :actual
        end
      end
    end

    def variables
      @variables ||= begin
        variables = @block.parameters.filter_map.with_index do |(type, name), i|
          case type
          when :req, :opt
            :actual if i == 0
          when :keyreq, :key
            name
          end
        end

        @substitution ? variables.map { @substitution[_1] || _1 } : variables
      end
    end

    def evaluate(values)
      values = substitute_hash(values, @substitution) if @substitution

      Utils.call_block(@block, values)
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(ProcExpression) &&
        other.block == @block &&
        other.substitution == @substitution
    end
    alias eql? ==

    def hash
      @block.hash
    end

    def substitute(replacements)
      replacements = replacements.slice(*variables)

      return self if replacements.empty?

      replacements = substitute_hash(@substitution, replacements) if @substitution

      ProcExpression.new(@block, substitution: replacements, to_s: @to_s)
    end

    def to_s(substitutions: nil)
      args_and_kwargs = Utils.inspect_block_params(@block)

      body = if @to_s
        arg0_type, arg0_name = @block.parameters[0]
        args = []
        kwargs = variables.to_h { [_1, Variable.new(_1)] }
        substitutions = variables.to_h { [_1, _1.to_s] }

        if %i[req opt rest].include?(arg0_type)
          args << kwargs.delete(:actual)
          substitutions[:actual] = arg0_name.to_s
        end

        Expression.with_substitutions(**substitutions) do
          @block.call(*args, **kwargs).inspect
        end
      else
        '...'
      end

      expr = @to_s ? 'expr_s' : 'expr'

      if args_and_kwargs.empty?
        "#{expr} { #{body} }"
      else
        "#{expr} { |#{args_and_kwargs}| #{body} }"
      end
    end

    private

    def substitute_hash(hash, substitution)
      hash.to_h do |k, v|
        k2 = substitution[k]
        v2 = k2.nil? && !substitution.key?(k2) ? v : hash[k2]

        [k, v2]
      end
    end
  end
end
