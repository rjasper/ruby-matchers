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
          Utils.call_block(value, actual, **values)
        else
          value
        end
      end

      errors << @matcher.match(actual, **values, **assigns)
    end
    protected :check
  end
end
