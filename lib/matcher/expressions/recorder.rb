# frozen_string_literal: true

module Matcher
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
          return Recorder.recorder?(args[0]) &&
            @expression.eql?(Recorder.to_expression(args[0]))
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
