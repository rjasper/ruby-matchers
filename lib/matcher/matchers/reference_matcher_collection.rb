# frozen_string_literal: true

module Matcher
  class ReferenceMatcherCollection
    attr_reader :last_object_id, :last_matcher

    def initialize
      @targets = {}
      @options = {}
      @last_object_id = nil
      @last_matcher = nil
      @used = Set.new
    end

    def check
      target_set = @targets.keys.reject { _1.start_with?('~') }.to_set
      missing_targets = @used - target_set
      unused_refs = target_set - @used

      raise "undefined ref: #{missing_targets.join(', ')}" unless missing_targets.empty?
      raise "unused ref: #{unused_refs.join(', ')}" unless unused_refs.empty?
    end

    def [](key, cyclic: false)
      @used << key

      ReferenceMatcher.new(key, @targets, @options, cyclic:)
    end

    DEFAULT_OPTIONS = { cache: true }.freeze

    def []=(key, matcher_or_options, matcher = NULL)
      raise "Cannot reassign reference: #{key.inspect}" if @targets.key?(key)

      if Matcher.null?(matcher)
        options = DEFAULT_OPTIONS
        matcher = matcher_or_options
      else
        options = matcher_or_options.merge(cache: true) { |_k, l, r| l }
      end

      @last_object_id = matcher.object_id
      matcher = Matcher.of(matcher)
      @last_matcher = matcher
      @targets[key] = matcher
      @options[key] = options
    end
  end
end
