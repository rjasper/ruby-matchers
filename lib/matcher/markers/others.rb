# frozen_string_literal: true

module Matcher
  class Others
    include Singleton

    def to_s
      'others'
    end
    alias inspect to_s
  end

  module MatcherBuilding
    def others
      Others.instance
    end
  end
end
