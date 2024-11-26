# frozen_string_literal: true

module Matcher
  module RuleDefinition
    def self.included(base)
      base.instance_exec do
        extend PatternBuilding
        extend RuleBuilding

        @rules = []

        class << self
          attr_reader :rules
        end
      end
    end
  end
end
