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
      @paths = []
      @counter = 0

      tree = catch(:abort) do
        analyze(@expression, nil)
      end

      paths = @paths
      @paths = nil

      if tree
        n = paths.length

        return split_call(@expression, nil) if n == 1

        if n > 1
          @common_ids, common_expression = find_common_expression(paths)
          @counter = 0

          if common_expression
            substituted_tree = substitute(@expression, tree)
            @common_ids = nil

            return split_call(common_expression, List.new(substituted_tree))
          end
        end
      end

      [@expression]
    end

    Tree = Struct.new(:subtrees, :id)
    IdExpression = Struct.new(:id, :expression)
    List = Struct.new(:head, :tail) do
      def to_a
        tail ? tail.to_a.unshift(head) : [head]
      end
    end

    private

    def analyze(expression, trace)
      case expression
      when Call
        id = (@counter += 1)
        id_expression = IdExpression.new(id, expression)
        next_trace = List.new(id_expression, trace)
        receiver_tree = analyze(expression.receiver, next_trace)

        arg_subtrees = expression.args.lazy.with_index.filter_map do |arg, i|
          arg_tree = analyze(arg, next_trace)
          [i, arg_tree] if arg_tree
        end.to_h

        kwarg_subtrees = expression.kwargs.lazy.filter_map do |key, value|
          kwarg_tree = analyze(value, next_trace)
          [key, kwarg_tree] if kwarg_tree
        end.to_h

        subtrees = {}
        subtrees[:receiver] = receiver_tree if receiver_tree
        subtrees[:args] = Tree.new(arg_subtrees) unless arg_subtrees.empty?
        subtrees[:kwargs] = Tree.new(kwarg_subtrees) unless kwarg_subtrees.empty?

        Tree.new(subtrees, id) unless subtrees.empty?
      when Variable
        return if expression.symbol != :actual

        @paths << trace
      when BlockExpression
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
          left = paths[0].tail
          right = paths[i].tail

          left && right && expressions_equal?(left.head.expression, right.head.expression)
        end

        paths.map!(&:tail)
      end

      [paths.map { _1.head.id }, paths[0].head.expression]
    end

    def substitute(expression, tree)
      subtrees = tree.subtrees
      return expression unless subtrees

      if tree.id == @common_ids[@counter]
        @counter += 1

        return Variable.actual
      end

      receiver_tree = subtrees[:receiver]
      receiver = if receiver_tree
        substitute(expression.receiver, receiver_tree)
      else
        expression.receiver
      end

      args_tree = subtrees[:args]
      args = if args_tree
        args_tree.subtrees.map do |i, arg_tree|
          substitute(expression.args[i], arg_tree)
        end
      else
        expression.args
      end

      kwargs_tree = subtrees[:kwargs]
      kwargs = if kwargs_tree
        kwargs_tree.subtrees.to_h do |k, kwarg_tree|
          [k, substitute(expression.kwargs[k], kwarg_tree)]
        end
      else
        expression.kwargs
      end

      Call.new(receiver, expression.method, *args, **kwargs, &expression.block)
    end

    def split_call(expression, tail)
      trace = nil
      segment = expression
      cur = expression

      while cur.is_a?(Call)
        if cur.method == :[] && cur.binary?
          t = trace
          e = nil
          while t
            e = t.head.new_root(e || Variable.actual)
            t = t.tail
          end

          tail = List.new(e, tail) if e
          tail = List.new(cur.args[0], tail)

          trace = nil
          segment = cur.receiver
        else
          trace = List.new(cur, trace)
        end

        cur = cur.receiver
      end

      result = if segment.is_a?(Variable) && segment.symbol == :actual
        tail
      else
        List.new(segment, tail)
      end

      result.to_a
    end
  end
end
