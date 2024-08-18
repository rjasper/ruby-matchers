# frozen_string_literal: true

module Matcher
  class SetVariablesMatcher < Base
    def initialize(assigns, matcher)
      super()

      @assigns = assigns
      @matcher = matcher
    end

    def check(actual, **values)
      assigns = @assigns.transform_values do |value|
        if value.is_a?(Proc)
          call_assign_block(value, actual, values)
        else
          value
        end
      end

      errors << @matcher.match(actual, **values, **assigns)
    end

    private

    def call_assign_block(assign_block, actual, values)
      args = []
      kwargs = {}

      assign_block.parameters.each do |type, name|
        case type
        when :req, :opt, :rest
          args << actual if args.length == 0
        when :keyreq
          kwargs[name] = values[name]
        when :key
          value = values[name]
          kwargs[name] = value if !value.nil? || values.key?(name)
        when :keyrest
          kwargs.merge!(values.except(*kwargs.keys))
        end
      end

      assign_block.call(*args, **kwargs)
    end
  end
end
