# frozen_string_literal: true

module Matcher
  class ReferenceMatcher < Base
    def initialize(targets, key, cyclic: nil, negated: false)
      super()

      @targets = targets
      @key = key
      @cyclic = cyclic
      @negated = negated

      @targets["~#{key}"] ||= nil if negated # reserve entry for later use (thread-safety)
    end

    def negated
      ReferenceMatcher.new(@targets, @key, cyclic: @cyclic, negated: !@negated)
    end

    def check(**)
      actual = get_actual(**)

      unless visited.add?(actual.object_id)
        errors << 'cyclic structure: actual has already been visited' if !@cyclic && !@negated
        return
      end

      match_key = [@negated ? "~#{@key}" : @key, actual.object_id]
      match_result = matched[match_key]

      if match_result.nil?
        target_errors = @cyclic ? target.match(actual:) : target.match(**)

        matched[match_key] = target_errors.valid?

        errors << target_errors
      elsif !match_result
        errors << 'actual has already failed before'
      end
    end

    def to_s
      "#{'~' if @negated}refs[#{@key.inspect}]"
    end

    private

    def visited
      session[:visited] ||= Set.new
    end

    def matched
      class_session[:matched] ||= Hash.new
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
