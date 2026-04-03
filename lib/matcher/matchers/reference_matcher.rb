# frozen_string_literal: true

module Matcher
  ##
  # Build recursive matchers.
  #   m = Matcher.build do
  #     refs[:list] = {
  #       head: Integer,
  #       tail: optional(refs[:list]),
  #     }
  #   end
  #
  #   m.match?({ head: 1, tail: { head: 2, tail: nil } })
  #   # => true
  #   m.match({ head: 1, tail: { head: "two", tail: nil } })
  #   # > root[:tail][:head]: expected a kind of Integer but got "two"
  #
  # == Allow cyclic references
  #
  # By default, reference matchers won't allow visiting the same object twice.
  # However, for structures like graphs we can enable cyclic mode. When the
  # reference matcher revisits an object it will assume a new match would be
  # the same as the first match result and skip traversal.
  #
  # Also note, that when caching is enabled values won't be passed to the target
  # matcher to ensure results are reproducible for the same object.
  #
  #   m = Matcher.build do
  #     refs[:vertex] = {
  #       name: String,
  #       edges: each(refs[:edge, cyclic: true]),
  #     }
  #
  #     refs[:edge] = {
  #       weight: Integer,
  #       destination: refs[:vertex, cyclic: true],
  #     }
  #
  #     { vertices: each(refs[:vertex]) }
  #   end
  #
  #   a = { name: 'a', edges: [] }
  #   b = { name: 'b', edges: [] }
  #   c = { name: 'c', edges: [] }
  #
  #   a[:edges] << { weight: 1, destination: b }
  #   b[:edges] << { weight: 2, destination: c }
  #   c[:edges] << { weight: "3", destination: a }
  #
  #   graph = { vertices: [a, b, c] }
  #
  #   m.match(graph)
  #   # > root[:vertices][0][:edges][0][:destination][:edges][0][:destination]~
  #   #   [:edges][0][:weight]: expected a kind of Integer but got "3"
  #   # > root[:vertices][1]: actual has already failed before
  #   # > root[:vertices][2]: actual has already failed before
  #
  # == Disable cache
  #
  # By default, results are cached for each object during a match session.
  # However, if a result depends not only on the actual value but also on other
  # passed values then the cache may return an incorrect result. See the example
  # below:
  #
  #   m = Matcher.build do
  #     refs[:foo] = _ == vars[:a]
  #
  #     [
  #       let(a: 1) ^ refs[:foo],
  #       let(a: 2) ^ refs[:foo],
  #     ]
  #   end
  #
  #   # should only match [1, 2] but refs[:foo] caches result for 1 as valid:
  #
  #   m.match?([1, 1])
  #   # => true, but shouldn't
  #
  #   # disable cache when matching result depends on other values than actual:
  #
  #   m = Matcher.build do
  #     refs[:foo, { cache: false }] = _ == vars[:a]
  #
  #     [
  #       let(a: 1) ^ refs[:foo],
  #       let(a: 2) ^ refs[:foo],
  #     ]
  #   end
  #
  #   m.match([1, 1])
  #   # > root[1]: expected actual == a but got 1 == 2
  class ReferenceMatcher < Base
    Settings = Struct.new(:target, :cache)

    def initialize(
      key,
      settings,
      cyclic: nil,
      negated: false,
      session_key: object_id
    )
      super()

      @key = key
      @settings = settings
      @cyclic = cyclic
      @negated = negated
      @session_key = session_key
    end

    def negate
      ReferenceMatcher.new(
        @key,
        @settings,
        cyclic: @cyclic,
        negated: !@negated,
        session_key: @session_key,
      )
    end

    def validate(state)
      actual = state.actual
      sess = class_session
      depth = sess[:depth]
      depth = depth ? depth + 1 : 1
      sess[:depth] = depth

      if depth > Matcher.max_reference_depth
        state.errors << "match level too deep: #{depth}"
        return
      end

      unless visited.add?(actual.object_id)
        if @negated == @cyclic
          state.errors << state.report.namespace(:reference).cyclic
        end

        return
      end

      unless cache?
        state.errors << yield(target)
        return
      end

      cache = (sess[:cache] ||= {})
      cache_key = [@key, actual.object_id]
      cached_result = cache[cache_key]

      if cached_result.nil?
        # If @cyclic then call #match instead of yield. We disallow passing
        # previous values for cyclic reference matchers. #match will create a
        # new values stack.
        target_errors = @cyclic ? target.match(actual) : yield(target)
        cache[cache_key] = @negated ^ target_errors.valid?

        state.errors << target_errors
      elsif @negated == cached_result
        state.errors << state.report.namespace(:reference).failed_from_cache
      end
    ensure
      sess[:depth] = depth - 1
    end

    def to_s
      "#{'~' if @negated}refs[#{@key.inspect}]"
    end

    private

    def cache?
      return @cache if defined? @cache

      @cache = @settings[@key].cache
    end

    def visited
      session(@session_key)[:visited] ||= Set.new
    end

    def target
      return @target if defined? @target

      pair = @settings[@key].target

      raise "No target for #{@key.inspect}" unless pair

      @target = if @negated
        pair[1] ||= ~pair[0]
      else
        pair[0]
      end
    end
  end

  module MatcherDsl
    def refs?
      !@refs.nil?
    end

    ##
    # Returns the reference matcher collection for recursive matchers
    # @example
    #   refs[:list] = {
    #     head: Integer,
    #     tail: optional(refs[:list]),
    #   }
    # @return [ReferenceMatcherCollection]
    def refs
      @refs ||= ReferenceMatcherCollection.new(self)
    end
  end
end
