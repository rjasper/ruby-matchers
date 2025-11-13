# frozen_string_literal: true

module Matcher
  class Builder
    include ExpressionBuilding
    include MatcherBuilding

    def initialize(outside, build_session: Matcher.build_session)
      ExpressionBuilding.init(self, build_session)

      @outside = outside
      @matcher_cache = MatcherCache.current(build_session)
    end

    ##
    # Turns a matchable value into a matcher
    # @example
    #   of(String).class # => Matcher::KindOfMatcher
    #   of(String) & !_.empty? # matches non-empty strings
    # @param value
    # @return [Base]
    def matcher_of(value)
      Matcher.of(
        value,
        matcher_cache: @matcher_cache,
        expression_cache: @expression_cache,
      )
    end
    alias of matcher_of

    ##
    # Accesses the outside context within a build block
    # @example
    #   class MyClass
    #     def initialize
    #       @ivar = 42
    #     end
    #
    #     def my_method
    #       "my string"
    #     end
    #
    #     def my_matcher
    #       Matcher.build do
    #         # @ivar and self.my_method not accessible from here
    #         [outside { @ivar }, outside.my_method]
    #       end
    #     end
    #   end
    # @return [Object] the outside context
    def outside(&)
      if block_given?
        @outside.instance_eval(&)
      else
        @outside
      end
    end

    ##
    # Negates a matcher
    # @example
    #   # matches anything except 1
    #   neg(1)
    #   # alternatively:
    #   ~equal(1)
    # @param matcher
    # @return [Base]
    # @see Base#~
    def neg(matcher)
      ~matcher_of(matcher)
    end

    ##
    # Matches given matcher but not +nil+
    #
    # This is useful to prevent accidentally matching against +nil+:
    #   def definitely_not_nil
    #     nil # shoot
    #   end
    #
    #   my_value = definitely_not_nil
    #   m = Matcher.build { present(my_value) }
    #   m.match?(nil) # => false
    #
    #   my_value = "fixed"
    #   m = Matcher.build { present(my_value) }
    #   m.match?("fixed") # => true
    # @example
    #   present(my_value)
    # @param matcher
    # @return [AllMatcher]
    def present(matcher)
      AllMatcher.new([
        ~equal(nil),
        matcher_of(matcher),
      ])
    end
  end
end
