# frozen_string_literal: true

module Matcher
  MatcherCache = Struct.new(
    :equal_matchers,
    :expression_matchers,
    :kind_of_matchers,
    :optionals,
    :optional_matchers,
    :range_matchers,
    :regexp_matchers,
  ) do
    def self.current(build_session = Matcher.build_session)
      build_session[:_matcher_cache] ||= new if build_session
    end
  end
end
