# frozen_string_literal: true

module Matcher
  class BlockExpression < Expression
    attr_reader :block

    def initialize(to_s: false, &block)
      super()

      @block = block
      @to_s = to_s
    end

    def variables
      @variables ||= @block.parameters.filter_map.with_index do |(type, name), i|
        case type
        when :req, :opt
          :actual if i == 0
        when :keyreq, :key
          name
        end
      end
    end

    def evaluate(values)
      Utils.call_block(@block, values)
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(BlockExpression) &&
        other.block == @block
    end
    alias eql? ==

    def hash
      @block.hash
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
  end
end
