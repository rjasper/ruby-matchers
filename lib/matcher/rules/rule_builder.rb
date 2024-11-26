# frozen_string_literal: true

module Matcher
  class RuleBuilder
    include PatternBuilding
    include RuleBuilding

    def initialize(rules = [])
      @rules = rules
    end

    attr_reader :rules
  end
end
