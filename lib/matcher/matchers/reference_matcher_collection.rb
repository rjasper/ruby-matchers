# frozen_string_literal: true

module Matcher
  class ReferenceMatcherCollection
    include NoMatcher
    include NoExpression
    include NoKey

    attr_reader :last_object_id, :last_matcher

    def initialize(builder)
      @settings = {}
      @last_object_id = nil
      @last_matcher = nil
      @used = Set.new
      @builder = builder
    end

    def finalize
      @settings.freeze

      assigned = @settings.each_key.to_set
      missing = @used - assigned
      unused = assigned - @used

      raise "undefined ref: #{missing.join(', ')}" unless missing.empty?
      raise "unused ref: #{unused.join(', ')}" unless unused.empty?
    end

    def [](key, cyclic: false)
      @used << key

      ReferenceMatcher.new(key, @settings, cyclic:)
    end

    DEFAULT_OPTIONS = { cache: true }.freeze

    def []=(key, matcher_or_options, matcher = UNDEFINED)
      raise "Cannot reassign reference: #{key.inspect}" if @settings.key?(key)

      if Matcher.undefined?(matcher)
        options = DEFAULT_OPTIONS
        matcher = matcher_or_options
      else
        options = matcher_or_options.merge(cache: true) { |_k, l, r| l }
      end

      @last_object_id = matcher.__id__
      matcher = @builder.matcher_of(matcher)
      @last_matcher = matcher

      settings = (@settings[key] ||= ReferenceMatcher::Settings.new)
      settings.target = [matcher, nil]
      settings.cache = options[:cache]
    end
  end
end
