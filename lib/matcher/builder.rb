# frozen_string_literal: true

require 'singleton'

module Matcher
  class Builder
    include ExpressionBuilding
    include MatcherBuilding

    def initialize(outside)
      @outside = outside
    end

    def outside(&)
      if block_given?
        @outside.instance_eval(&)
      else
        @outside
      end
    end
  end
end
