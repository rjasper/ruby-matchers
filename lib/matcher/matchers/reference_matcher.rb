# frozen_string_literal: true

module Matcher
  class ReferenceMatcher < Base
    def initialize(key, targets, options, cyclic: nil, negated: false, session_key: nil)
      super()

      @targets = targets
      @key = key
      @cyclic = cyclic
      @options = options
      @negated = negated
      @session_key = session_key

      @targets["~#{key}"] ||= nil if negated # reserve entry for later use (thread-safety)
    end

    def negated
      ReferenceMatcher.new(@key, @targets, @options, cyclic: @cyclic, negated: !@negated, session_key: object_id)
    end

    def check(**)
      actual = get_actual(**)

      unless visited.add?(actual.object_id)
        if !@negated && !@cyclic
          errors << 'cyclic structure: actual has already been visited'
        elsif @negated && @cyclic
          errors << 'expected not a valid cyclic structure'
        end

        return
      end

      unless @options[@key][:cache]
        errors << target.match(**)
        return
      end

      cache_key = [@negated ? "~#{@key}" : @key, actual.object_id]
      cached_result = cache[cache_key]

      if cached_result.nil?
        target_errors = @cyclic ? target.match(actual:) : target.match(**)

        cache[cache_key] = target_errors.valid?

        errors << target_errors
      elsif !cached_result
        errors << 'actual has already failed before'
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
end
