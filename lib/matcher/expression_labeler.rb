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
        label_for([Constant, expression.value])
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
      when ProcExpression
        label_for([ProcExpression, expression.block])
      when ArrayExpression, SetExpression
        items_l = expression.items.map { label(_1, actual_label) }

        label_for([expression.class, items_l])
      when HashExpression
        pairs_l = expression.pairs.flat_map do |k, v|
          [label(k, actual_label), label(v, actual_label)]
        end

        label_for([HashExpression, pairs_l])
      when RangeExpression
        begin_l = label(expression.begin, actual_label)
        end_l = label(expression.end, actual_label)

        label_for([RangeExpression, begin_l, end_l, expression.exclude_end?])
      when RescueLastErrorExpression
        expression_l = label(expression.expression, actual_label)

        label_for([RescueLastErrorExpression, expression_l])
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
        ])
      when SymbolProc
        label_for([SymbolProc, block.symbol])
      else # nil, Proc
        label_for(block)
      end
    end
  end
end
