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

      @targets["~#{key}"] ||= nil if negated # reserve entry for later use (thread-safety)
    end

    def ~
      ReferenceMatcher.new(@key, @targets, @options, cyclic: @cyclic, negated: !@negated, session_key: @session_key)
    end

    def check(state)
      actual = state.actual

      unless visited.add?(actual.object_id)
        state.errors << report.namespace(:reference).cyclic if @negated == @cyclic

        return
      end

      unless @options[@key][:cache]
        state.errors << yield(target)
        return
      end

      cache_key = [@negated ? "~#{@key}" : @key, actual.object_id]
      cached_result = cache[cache_key]

      if cached_result.nil?
        target_errors = @cyclic ? target.match(actual) : yield(target)

        cache[cache_key] = target_errors.valid?

        state.errors << target_errors
      elsif !cached_result
        state.errors << report.namespace(:reference).failed_from_cache
      end
    end

    def to_s
      "#{'~' if @negated}refs[#{@key.inspect}]"
    end

    private

    def visited
      session(@session_key)[:visited] ||= Set.new
    end

    def cache
      class_session[:cache] ||= Hash.new
    end

    def target
      target = @targets[@key]

      raise "No target for #{@key.inspect}" if target.nil? && !@targets.key?(@key)

      if @negated
        @targets["~#{@key}"] ||= ~target
      else
        target
      end
    end
  end

  module MatcherBuilding
    def refs?
      !@refs.nil?
    end

    def refs
      @refs ||= ReferenceMatcherCollection.new
    end
  end
end
