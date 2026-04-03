# frozen_string_literal: true

module Matcher
  class NestedExpressionNormalizer
    def self.normalize(expression)
      new(expression).run
    end

    def initialize(expression)
      @expression = expression
    end

    def run
      return [] if @expression == Variable.actual

      tree, paths = analyze

      return [@expression] unless tree

      n = paths.length

      if n == 1 && paths[0]
        actual_chain = paths[0].last

        if actual_chain.expression == @expression
          return split(@expression, List.empty)
        end

        last = substitute([actual_chain.id], tree)

        return split(actual_chain.expression, List.one(last))
      elsif n > 1
        common_expression, ids = find_common_expression(paths)

        if common_expression
          last = substitute(ids, tree)

          return split(common_expression, List.one(last))
        end
      end

      [@expression]
    end

    Tree = Struct.new(:subtrees, :id)
    IdExpression = Struct.new(:id, :expression)

    private

    def analyze
      @paths = []
      @counter = 0

      tree = catch(:abort) do
        analyze_helper(@expression, List.empty)
      end

      paths = @paths
      @paths = nil

      [tree, paths]
    end

    def analyze_helper(expression, trace)
      case expression
      when Call
        id = (@counter += 1)
        id_expression = IdExpression.new(id, expression)
        next_trace = trace << id_expression
        receiver_tree = analyze_helper(expression.receiver, next_trace)

        arg_trees = expression.args.lazy.with_index.filter_map do |arg, i|
          arg_tree = analyze_helper(arg, List.empty)
          [i, arg_tree] if arg_tree
        end.to_h

        kwarg_trees = expression.kwargs.lazy.filter_map do |key, value|
          kwarg_tree = analyze_helper(value, List.empty)
          [key, kwarg_tree] if kwarg_tree
        end.to_h

        subtrees = {}
        subtrees[:receiver] = receiver_tree if receiver_tree
        subtrees[:args] = Tree.new(arg_trees) unless arg_trees.empty?
        subtrees[:kwargs] = Tree.new(kwarg_trees) unless kwarg_trees.empty?

        Tree.new(subtrees, id) unless subtrees.empty?
      when Variable
        return if expression.symbol != :actual

        @paths << trace unless trace.empty?
      when ProcExpression
        throw(:abort) if expression.variables.include?(:actual)
      else
        nil
      end
    end

    def expressions_equal?(left, right)
      left.method == right.method &&
        left.args == right.args &&
        left.kwargs == right.kwargs &&
        left.block == right.block
    end

    def find_common_expression(paths)
      # method destroys paths which is OK

      n = paths.length

      return if !paths.all? || !(1...n).all? do |i|
        expressions_equal?(paths[0].head.expression, paths[i].head.expression)
      end

      loop do
        break unless (1...n).all? do |i|
          left = paths[0].tail&.head
          right = paths[i].tail&.head

          left && right && left.id != right.id &&
            expressions_equal?(left.expression, right.expression)
        end

        paths.map!(&:tail)
      end

      [paths[0].head.expression, paths.map { _1.head.id }]
    end

    def substitute(ids, tree)
      @substitute_ids = ids
      @counter = 0
      result = substitute_helper(@expression, tree)
      @substitute_ids = nil

      result
    end

    def substitute_helper(expression, tree)
      subtrees = tree.subtrees
      return expression unless subtrees

      if tree.id == @substitute_ids[@counter]
        @counter += 1

        return Variable.actual
      end

      receiver_tree = subtrees[:receiver]
      receiver = if receiver_tree
        substitute_helper(expression.receiver, receiver_tree)
      else
        expression.receiver
      end

      args_tree = subtrees[:args]
      args = if args_tree
        args_tree.subtrees.map do |i, arg_tree|
          substitute_helper(expression.args[i], arg_tree)
        end
      else
        expression.args
      end

      kwargs_tree = subtrees[:kwargs]
      kwargs = if kwargs_tree
        kwargs_tree.subtrees.to_h do |k, kwarg_tree|
          [k, substitute_helper(expression.kwargs[k], kwarg_tree)]
        end
      else
        expression.kwargs
      end

      Call.new(receiver, expression.method, args, kwargs, expression.block)
    end

    def split(expression, tail)
      trace = List.empty
      segment = expression
      cur = expression

      while cur.is_a?(Call)
        if cur.method == :[] && cur.binary?
          e = !trace.empty? && trace.reduce(Variable.actual) do |expr, call|
            Call.new(expr, call.method, call.args, call.kwargs, call.block)
          end

          tail <<= e if e
          arg = cur.args[0]
          arg = arg.value if arg.is_a?(Constant)
          tail <<= arg

          trace = List.empty
          segment = cur.receiver
        else
          trace <<= cur
        end

        cur = cur.receiver
      end

      result = if segment.is_a?(Variable) && segment.symbol == :actual
        tail
      else
        tail << segment
      end

      result.to_a
    end
  end
end
