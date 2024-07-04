# frozen_string_literal: true

module Matcher
  class HashMatcher < Base
    def initialize(hash, all_entries: true)
      super()

      @hash = hash
      @all_entries = all_entries
    end

    def check(actual)
      unless actual.is_a?(Hash)
        errors << "expected a Hash but got #{actual.inspect}"
        return
      end

      check_all_entries(actual) if @all_entries

      @hash.each do |key, value|
        actual_value = actual[key]

        errors[key] << if actual_value.nil? && !actual.key?(key)
          "expected entry for #{key.inspect} but found nothing"
        else
          value.match(actual_value)
        end
      end
    end

    def inspect
      if @all_entries
        @hash.inspect
      else
        "partial_entries(#{@hash.inspect})"
      end
    end

    private

    def check_all_entries(actual)
      extra_keys = actual.keys - @hash.keys
      extra_keys.each do |key|
        errors[key] << "expected entry for #{key.inspect} to not be present"
      end
    end
  end
end
