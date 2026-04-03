# frozen_string_literal: true

module Matcher
  module ExpressionBuilding
    attr_reader :assigns

    def self.init(builder, build_session)
      builder.instance_exec do
        @expression_cache = ExpressionCache.current(build_session)
      end
    end

    def expression_of(value)
      Expression.of(value, expression_cache: @expression_cache)
    end

    def expression_or_value(value)
      Expression.expression_or_value(value, expression_cache: @expression_cache)
    end

    def declare(*symbols, **assigns)
      symbols.concat(assigns.keys - symbols)
      conflicts = symbols & methods

      if conflicts.length > 1
        raise "Cannot declare these variables: #{conflicts.join(', ')}"
      elsif conflicts.length == 1
        raise "Cannot declare variable \"#{conflicts[0]}\""
      end

      symbols.each do |symbol|
        define_singleton_method(symbol) do
          vars[symbol]
        end
      end

      unless assigns.empty?
        if @assigns
          @assigns.merge!(assigns)
        else
          @assigns = assigns
        end
      end

      UNDEFINED
    end

    ##
    # Turns any object into a recorder, or a block into a recorder.
    #
    # == Turn an object into a recorder
    #
    # Note, that the arguments of a call are implicitly converted to
    # expressions. No need to use +expr+ on the right-hand-side of an operator.
    #
    #   # BAD
    #   expr(Time).now + expr(3600)
    #
    #   # GOOD
    #   expr(Time).now + 3600
    #
    # This also works for deeply nested Hashes, Arrays and Sets:
    #
    #   my_expr = Matcher::Expression.build do
    #     expr([{ foo: Set[vars[:a]] }])
    #   end
    #
    #   my_expr.evaluate(a: 42) # => [{:foo=>#<Set: {42}>}]
    #
    # == Turn a block into a recorder
    #
    #   my_expr = Matcher::Expression.build do
    #     expr { |actual| actual ? 1 : 2 }
    #   end
    #
    #   my_expr.evaluate(true) # => 1
    #   my_expr.inspect my_expr # => "expr { ... }"
    #
    # The disadvantage of block expressions is that we cannot inspect them
    # easily. So they should be avoided if possible. Alternatively, consider
    # using inline matchers or implement a new matcher class.
    #
    # @example
    #   # turn object into recorder
    #   expr(Time).now
    #   expr(1) + vars[:a]
    #   # deeply nested structures are supported
    #   expr([{ foo: Set[vars[:a]] }])
    #   # turn block into expression (not inspectable)
    #   expr { |actual| actual ? 1 : 2 }
    # @overload expr(obj)
    #   @param obj the object to wrap
    #   @return [Recorder]
    # @overload expr(&block)
    #   @return [Recorder]
    def expr(obj = UNDEFINED, &block)
      raise "obj and block given" if !Matcher.undefined?(obj) && block_given?

      expression = block_given? ? ProcExpression.new(block) : expression_of(obj)
      expression.to_recorder
    end

    ##
    # Builds a range expression where +from+ and +to+ can be expressions
    # @example
    #   range(0, vars[:limit])
    #   # evaluates to 0..10 when limit: 10
    # @param from [Expression, Object]
    # @param to [Expression, Object]
    # @param exclude_end [Boolean]
    # @return [RangeExpression]
    def range(from, to, exclude_end: false)
      from = expression_of(from)
      to = expression_of(to)

      RangeExpression.new(from, to, exclude_end:).to_recorder
    end

    def rescue_exception(expression)
      expression = expression_of(expression)
      rescue_last_error = RescueLastErrorExpression.new(expression)

      expression_of(rescue_last_error).to_recorder
    end

    ##
    # Returns a recorder for +Kernel+, useful for calling Kernel methods
    # @example
    #   kernel.Integer(vars[:a]) # => Integer(a)
    # @return [Recorder]
    def kernel
      expr(Kernel)
    end

    ##
    # Concatenates expressions into a string expression
    # @example
    #   concat('foo=', vars[:foo])
    #   # evaluates to "foo=23" when foo: 23
    # @param parts [Array<Expression, Object>]
    # @return [Recorder]
    def concat(*parts)
      parts = parts.map { expression_of(_1) }
      string_expression = StringExpression.new(parts)

      expression_of(string_expression).to_recorder
    end

    ##
    # Returns a recorder for the actual value being matched
    # @example
    #   _ > 10
    #   _.even?
    #   _.length == 3
    # @return [Recorder]
    def actual
      vars[:actual]
    end
    alias _ actual

    ##
    # Returns a recorder for the current hash key
    # @example
    #   each_pair(k.to_s == v)
    # @return [Recorder]
    def key
      vars[:key]
    end
    alias k key

    ##
    # Returns a recorder for the current hash value
    # @example
    #   each_pair(k.to_s == v)
    # @return [Recorder]
    def value
      vars[:value]
    end
    alias v value

    ##
    # Returns a recorder for the current element index
    # @example
    #   each(_ == i)
    # @return [Recorder]
    def index
      vars[:index]
    end
    alias i index

    ##
    # Returns a recorder for the parent collection
    # @example
    #   each(_ < parent.length)
    # @return [Recorder]
    def parent
      vars[:parent]
    end

    ##
    # Returns a recorder for the original value before mapping
    # @return [Recorder]
    # @see MatcherBuilding#map
    def original
      vars[:original]
    end

    ##
    # Evaluates block with +&+ and +|+ acting as +&&+ and +||+
    #
    # We cannot capture `&&` and `||` directly when building expressions. But as
    # a workaround we can substitute them with `&` and `|`.
    #
    #   lo { (_ % 4 == 0) & (_ % 100 != 0) | (_ % 400 != 0) }
    #   # => actual % 4 == 0 && actual % 100 != 0 || actual % 400 != 0
    #
    # Note that +&+ and +|+ have different precedence than +&&+ and +||+:
    #
    #   Matcher::Expression.build do
    #     lo { vars[:foo] | vars[:bar] < 2 }
    #   end
    #   # => (foo || bar) < 2
    # @return [Recorder]
    def logical_operators(&)
      Matcher.with_settings(logical_operators: true, &)
    end
    alias lo logical_operators

    ##
    # Passes blocks through to the actual call instead of evaluating them
    # as expression builders
    # @example
    #   class Foo
    #     def initialize(foo)
    #       @foo = foo
    #     end
    #   end
    #
    #   my_expr = Matcher::Expression.build do
    #     ptb do
    #       _.instance_exec { @foo }
    #     end
    #   end
    #
    #   foo = Foo.new("foo")
    #
    #   my_expr.evaluate(actual: foo) # => 'foo'
    # @return [Recorder]
    def pass_through_blocks(arg = UNDEFINED, &)
      # Note that arg might be a recorder where #nil? won't work.

      if Matcher.undefined?(arg)
        Matcher.with_settings(pass_through_blocks: true, &)
      else
        Matcher.with_settings(pass_through_blocks: true) do
          yield arg
        end
      end
    end
    alias ptb pass_through_blocks

    ##
    # Captures calls to assignment methods
    # @example
    #   assign { _.foo = 1 }     # => actual.foo = 1
    #   assign { _[:foo] = 1 }   # => actual[:foo] = 1
    # @return [Recorder]
    def assign
      value = expression_of(yield)
      call = Call.last_assign

      Call.reset_last_assign

      status = if call&.assignment?
        arg = call.args.last

        if value.is_a?(Constant)
          arg.is_a?(Constant) && value.value.equal?(arg.value)
        else
          value.equal?(arg)
        end
      end

      raise "Could not return last assignment" unless status

      call.to_recorder
    end

    ##
    # Returns the variable factory for accessing named variables
    # @example
    #   vars[:my_value]
    #   _ == vars[:limit]
    # @return [VariableFactory]
    def vars
      @vars ||= VariableFactory.new(@expression_cache)
    end

    class VariableFactory
      include NoMatcher
      include NoExpression
      include NoKey

      def initialize(expression_cache)
        @expression_cache = expression_cache
      end

      def [](symbol)
        Variable.cache(symbol, expression_cache: @expression_cache).to_recorder
      end
    end
  end
end
