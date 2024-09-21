# frozen_string_literal: true

module Matcher
  class ReferenceMatcher < Base
    def initialize(targets, key, cyclic: nil, negated: false)
      @targets = targets
      @key = key
      @cyclic = cyclic
      @negated = negated
    end

    def negated
      ReferenceMatcher.new(@targets, @key, cyclic: @cyclic, negated: !@negated)
    end

    def check(**)
      actual = get_actual(**)
      # match_key = [@key, actual.object_id]
      # match_result = matched[match_key]
      #
      # unless match_result.nil?
      #   errors << 'actual has already failed before' unless match_result
      #   return
      # end

      unless visited.add?(actual.object_id)
        errors << 'actual has already been visited' if !@cyclic && !@negated
        return
      end

      errors << target.match(**)
    end

    def inspect
      "#{'~' if @negated}refs[#{@key.inspect}]"
    end

    private

    def visited
      session[:visited] ||= Set.new
    end

    # def matched
    #   class_session[:matched] ||= Hash.new
    # end

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
