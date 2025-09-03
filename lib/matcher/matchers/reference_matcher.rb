# frozen_string_literal: true

module Matcher
  class ReferenceMatcher < Base
    def initialize(key, targets, options, cyclic: nil, negated: false, session_key: object_id)
      super()

      @targets = targets
      @key = key
      @cyclic = cyclic
      @options = options
      @negated = negated
      @session_key = session_key
    end

    def negate
      ReferenceMatcher.new(@key, @targets, @options, cyclic: @cyclic, negated: !@negated, session_key: @session_key)
    end

    def check(state)
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
        state.errors << state.report.namespace(:reference).cyclic if @negated == @cyclic

        return
      end

      unless @options[@key][:cache]
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

    def visited
      session(@session_key)[:visited] ||= Set.new
    end

    def target
      pair = @targets[@key]

      raise "No target for #{@key.inspect}" unless pair

      if @negated
        pair[1] ||= ~pair[0]
      else
        pair[0]
      end
    end
  end

  module MatcherBuilding
    def refs?
      !@refs.nil?
    end

    def refs
      @refs ||= ReferenceMatcherCollection.new(self)
    end
  end
end
