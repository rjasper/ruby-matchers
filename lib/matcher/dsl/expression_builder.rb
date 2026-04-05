# frozen_string_literal: true

module Matcher
  class ExpressionBuilder
    include ExpressionDsl

    def initialize(build_session: Matcher.build_session)
      ExpressionDsl.init(self, build_session)
    end
  end
end
