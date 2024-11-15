# frozen_string_literal: true

module Matcher
  class ExpressionLabeler
    ROOT = 0

    def initialize
      @label_count = 0
      @label_index = {}
    end

    def label(expression, actual_label = ROOT)
      case expression
      when Constant
        label_for([Constant, expression.constant])
      when Variable
        if expression.symbol == :actual
          actual_label
        else
          label_for([Variable, expression.symbol])
        end
      when Call
        receiver_l = label(expression.receiver, actual_label)
        args_l = expression.args.map { label(_1, actual_label) }
        kwargs_l = expression.kwargs.transform_values { label(_1, actual_label) }
        block_l = label_for_block(expression.block)

        label_for([Call, receiver_l, expression.method, args_l, kwargs_l, block_l])
      when BlockExpression
        label_for([BlockExpression, expression.block])
      else
        raise "unexpected expression: #{expression.inspect}"
      end
    end

    private

    def label_for(key)
      @label_index[key] ||= (@label_count += 1)
    end

    def label_for_block(block)
      case block
      when Block
        label_for([
          Block,
          block.parameters,
          label(block.expression),
          label_for(block.context),
        ])
      when SymbolProc
        label_for([SymbolProc, block.symbol])
      else # nil, Proc
        label_for(block)
      end
    end
  end
end
