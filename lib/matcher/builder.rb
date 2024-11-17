# frozen_string_literal: true

require 'singleton'

module Matcher
  class Builder
    include ExpressionBuilding
    include MatcherBuilding
  end
end
