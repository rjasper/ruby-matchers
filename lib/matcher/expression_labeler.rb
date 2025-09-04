# frozen_string_literal: true

module Matcher
  class ExpressionLabeler
    ROOT = 0

    def initialize
      @label_count = 0

      @constant_labels = {}
      @variable_labels = {}
      @call_labels = {}
      @block_labels = {}
      @proc_labels = {}
      @array_labels = {}
      @set_labels = {}
      @hash_labels = {}
      @range_labels = {}
      @string_labels = {}
      @rescue_labels = {}
    end

    def label(expression, actual_label = ROOT)
      case expression
      when Constant
        label_for(@constant_labels, expression.value)
      when Variable
        if expression.symbol == :actual
          actual_label
        else
          label_for(@variable_labels, expression.symbol)
        end
      when Call
        receiver_l = label(expression.receiver, actual_label)
        args_l = expression.args.map { label(_1, actual_label) }
        kwargs_l = expression.kwargs.transform_values { label(_1, actual_label) }
        block_l = label_for_block(expression.block)

        label_for(@call_labels, [receiver_l, expression.method, args_l, kwargs_l, block_l])
      when ProcExpression
        label_for(@proc_labels, expression.block)
      when ArrayExpression
        items_l = expression.items.map { label(_1, actual_label) }

        label_for(@array_labels, items_l)
      when SetExpression
        items_l = expression.items.map { label(_1, actual_label) }

        label_for(@set_labels, items_l)
      when HashExpression
        pairs_l = expression.pairs.flat_map do |k, v|
          [label(k, actual_label), label(v, actual_label)]
        end

        label_for(@hash_labels, pairs_l)
      when RangeExpression
        begin_l = label(expression.begin, actual_label)
        end_l = label(expression.end, actual_label)

        label_for(@range_labels, [begin_l, end_l, expression.exclude_end?])
      when StringExpression
        parts_l = expression.parts.map { label(_1, actual_label) }

        label_for(@string_labels, parts_l)
      when RescueLastErrorExpression
        expression_l = label(expression.expression, actual_label)

        label_for(@rescue_labels, expression_l)
      else
        raise "unexpected expression: #{expression.inspect}"
      end
    end

    private

    def label_for(index, key)
      index[key] ||= (@label_count += 1)
    end

    def label_for_block(block)
      case block
      when Block
        label_for(@block_labels, [block.parameters, label(block.expression)])
      when SymbolProc
        label_for(@block_labels, block.symbol)
      else # nil, Proc
        label_for(@block_labels, block)
      end
    end
  end
end
