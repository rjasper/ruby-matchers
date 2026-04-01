# frozen_string_literal: true

module Matcher
  class Others
    include Singleton
    include NoMatcher
    include NoExpression

    def to_s
      'others'
    end
    alias inspect to_s
  end

  module MatcherBuilding
    ##
    # Hash key that matches remaining entries
    # @example
    #   {
    #     id: Integer,
    #     others => each_value(String),
    #   }
    # @return [Others]
    def others
      Others.instance
    end
  end
end
