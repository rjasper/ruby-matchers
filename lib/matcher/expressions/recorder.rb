# frozen_string_literal: true

module Matcher
  ##
  # The core building block of composing expressions is a method *call*. For
  # instance, <tt>a + b</tt> is a call where +a+ receives +b+ via its method
  # <tt>+</tt>.
  #
  # Our expression builder tracks Ruby calls with Recorder objects which work
  # like this:
  #   # let's build an AST for "Hello".upcase
  #
  #   # explicitly by hand
  #   hello = Matcher::Constant.new("Hello")
  #   hello_upcase = Matcher::Call.new(hello, :upcase)
  #   hello_upcase.evaluate({}) # => "HELLO"
  #
  #   # with recorder
  #   hello = Matcher::Constant.new("Hello")
  #   hello_rec = Matcher::Recorder.new(hello)
  #   hello_upcase_rec = hello_rec.upcase # the magic
  #   hello_upcase = Matcher::Recorder.to_expression(hello_upcase_rec)
  #   # => "Hello".upcase
  #   hello_upcase.evaluate({})
  #   # => "HELLO"
  #
  #   # with builder
  #   Matcher::Expression.build do
  #     expr("Hello").upcase
  #   end
  #
  # == Recorders are nasty
  #
  # To do their job any call to a recorder must return a new recorder. But this
  # also makes them ill-behaved because methods like <tt>==</tt> or
  # <tt>is_a?</tt> don't behave like you expect them to. They don't have any
  # methods defined (except +__id__+ and +__send__+). Instead, all calls are
  # handled by +method_missing+.
  #
  # The consequence:
  #   # let r be a recorder
  #   r = Matcher::Recorder.new(Matcher::Variable.actual)
  #
  #   # everything below returns a recorder
  #
  #   r == nil # truthy
  #   r != r # truthy
  #   !r # truthy
  #   !!r # still truthy
  #   r.class # not Recorder (but a Recorder instance)
  #   r.object_id # not an integer
  #   r.to_s # not a string
  #
  # This makes them very hard to deal with, should you encounter them where you
  # wouldn't expect them.
  class Recorder
    def self.recorder?(object)
      Object.instance_method(:kind_of?)
        .bind_call(object, Recorder)
    end

    def self.to_expression(recorder)
      Object.instance_method(:instance_variable_get)
        .bind_call(recorder, :@expression)
    end

    # NOTE: In order for Recorder to work, it can't have any methods except for
    # the ones below.

    (instance_methods - %i[__id__ __send__ object_id])
      .each { undef_method _1 }

    def initialize(expression)
      @expression = expression
    end

    def method_missing(method, *args, **kwargs, &block)
      # *.hash.to_int indicates that a Hash evaluates this recorder as a key.
      if @hash_parent # @hash_parent is set if @expression is a *.hash call.
        to_int = method == :to_int && args.empty? && kwargs.empty? && !block

        # Confirm to parent that indeed a Hash called it.
        Object.instance_method(:instance_variable_set)
          .bind_call(@hash_parent, :@hash_confirmed, to_int)

        return @expression.receiver.hash if to_int
      end

      # In "uncertain" state: Check if Hash called eql? on this recorder.
      if @hash_caller # @hash_caller indicates the "uncertain" state.
        if method == :eql? && @hash_confirmed && caller[0] == @hash_caller
          # Return proper eql? result.

          result = Recorder.recorder?(args[0]) &&
            @expression.eql?(Recorder.to_expression(args[0]))

          return result
        else # Not a call from Hash.
          # Leave the "uncertain" state and resume recorder behavior.
          @hash_caller = nil
          @hash_confirmed = false
        end
      end

      expression_cache = ExpressionCache.current
      args = args.map { Expression.of(_1, expression_cache:) }
      kwargs = kwargs.transform_values { Expression.of(_1, expression_cache:) }
      block = Block.build(expression_cache:, &block) if
        block && !Matcher.settings[:pass_through_blocks]

      expression = Call.new(@expression, method, args, kwargs, block)
      expression = expression_cache[expression] if expression_cache
      recorder = expression.to_recorder

      # A Hash might evaluate this recorder as a key.
      if method == :hash && args.empty? && kwargs.empty? && !block
        # If the new recorder registers a *.to_int call then it was called by a
        # Hash.

        # Enter the "uncertain" state. Save the caller for later check against
        # false positives.
        @hash_caller = caller[0]

        # Give reference to the new recorder for confirmation.
        Object.instance_method(:instance_variable_set)
          .bind_call(recorder, :@hash_parent, self)
      end

      recorder
    end

    def respond_to_missing?(...)
      true
    end
  end
end
